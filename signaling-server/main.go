package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

type Room struct {
	ID      string
	Peers   map[string]*Peer
	Created time.Time
	mu      sync.RWMutex
}

type Peer struct {
	ID         string
	Name       string
	DeviceType string
	IP         string
	Port       int
	Conn       *websocket.Conn
	Room       *Room
	SendChan   chan []byte
}

type Message struct {
	Type       string          `json:"type"`
	RoomCode   string          `json:"room,omitempty"`
	PeerID     string          `json:"peer_id,omitempty"`
	Name       string          `json:"name,omitempty"`
	DeviceType string          `json:"device_type,omitempty"`
	IP         string          `json:"ip,omitempty"`
	Port       int             `json:"port,omitempty"`
	Peers      []PeerInfo      `json:"peers,omitempty"`
	Data       json.RawMessage `json:"data,omitempty"`
}

type PeerInfo struct {
	ID         string `json:"id"`
	Name       string `json:"name"`
	DeviceType string `json:"device_type"`
	IP         string `json:"ip"`
	Port       int    `json:"port"`
}

type Server struct {
	rooms    map[string]*Room
	roomsMu  sync.RWMutex
	upgrader websocket.Upgrader
}

func NewServer() *Server {
	return &Server{
		rooms: make(map[string]*Room),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				// In production, implement proper CORS
				return true
			},
			ReadBufferSize:  1024,
			WriteBufferSize: 1024,
		},
	}
}

func (s *Server) handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		return
	}
	defer conn.Close()

	peerID := fmt.Sprintf("peer_%d", time.Now().UnixNano())

	// Get client IP
	clientIP := r.Header.Get("X-Forwarded-For")
	if clientIP == "" {
		clientIP = r.RemoteAddr
	}

	peer := &Peer{
		ID:       peerID,
		Conn:     conn,
		IP:       clientIP,
		SendChan: make(chan []byte, 256),
	}

	// Send peer ID to client
	welcomeMsg := Message{
		Type:   "welcome",
		PeerID: peerID,
	}
	welcomeData, _ := json.Marshal(welcomeMsg)
	conn.WriteMessage(websocket.TextMessage, welcomeData)

	// Start write pump
	go peer.writePump()

	// Read pump
	peer.readPump(s)
}

func (p *Peer) readPump(s *Server) {
	defer func() {
		if p.Room != nil {
			p.Room.removePeer(p)
		}
		p.Conn.Close()
	}()

	p.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	p.Conn.SetPongHandler(func(string) error {
		p.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, message, err := p.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("WebSocket error: %v", err)
			}
			break
		}

		var msg Message
		if err := json.Unmarshal(message, &msg); err != nil {
			log.Printf("JSON unmarshal error: %v", err)
			continue
		}

		s.handleMessage(p, msg)
	}
}

func (p *Peer) writePump() {
	ticker := time.NewTicker(54 * time.Second)
	defer func() {
		ticker.Stop()
		p.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-p.SendChan:
			p.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				p.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			p.Conn.WriteMessage(websocket.TextMessage, message)

		case <-ticker.C:
			p.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := p.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func (s *Server) handleMessage(p *Peer, msg Message) {
	switch msg.Type {
	case "register":
		// Update peer info
		p.Name = msg.Name
		p.DeviceType = msg.DeviceType
		p.Port = msg.Port
		log.Printf("Registered peer: %s (%s) at %s:%d", p.Name, p.DeviceType, p.IP, p.Port)

		// Auto-join discovery room
		s.joinRoom(p, "discovery")

		case "get_peers":
		if p.Room != nil {
			peers := p.Room.getPeerList(p)
			response := Message{
				Type:  "peers_list",
				Peers: peers,
			}
			data, _ := json.Marshal(response)
			select {
			case p.SendChan <- data:
			default:
			}
		}

	case "join_room":
		s.joinRoom(p, msg.RoomCode)
	case "leave_room":
		if p.Room != nil {
			p.Room.removePeer(p)
		}
	case "offer", "answer", "ice_candidate":
		if p.Room != nil {
			p.Room.broadcast(p, msg)
		}
	default:
		log.Printf("Unknown message type: %s", msg.Type)
	}
}

func (s *Server) joinRoom(p *Peer, roomCode string) {
	s.roomsMu.Lock()
	room, exists := s.rooms[roomCode]
	if !exists {
		room = &Room{
			ID:      roomCode,
			Peers:   make(map[string]*Peer),
			Created: time.Now(),
		}
		s.rooms[roomCode] = room
	}
	s.roomsMu.Unlock()

	room.addPeer(p)
	p.Room = room

	// Send current peers list to new peer
	peers := room.getPeerList(p)
	if len(peers) > 0 {
		peersList := Message{
			Type:  "peers_list",
			Peers: peers,
		}
		data, _ := json.Marshal(peersList)
		select {
		case p.SendChan <- data:
		default:
		}
	}

	// Notify all peers in room about new peer
	joinMsg := Message{
		Type:       "peer_joined",
		PeerID:     p.ID,
		Name:       p.Name,
		DeviceType: p.DeviceType,
		IP:         p.IP,
		Port:       p.Port,
	}
	data, _ := json.Marshal(joinMsg)
	for _, peer := range room.Peers {
		if peer.ID != p.ID {
			select {
			case peer.SendChan <- data:
			default:
			}
		}
	}
}

func (r *Room) addPeer(p *Peer) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.Peers[p.ID] = p
	log.Printf("Peer %s joined room %s", p.ID, r.ID)
}

func (r *Room) removePeer(p *Peer) {
	r.mu.Lock()
	defer r.mu.Unlock()
	delete(r.Peers, p.ID)
	log.Printf("Peer %s left room %s", p.ID, r.ID)

	// Notify remaining peers
	leaveMsg := Message{
		Type:   "peer_left",
		PeerID: p.ID,
	}
	leaveData, _ := json.Marshal(leaveMsg)
	r.broadcast(p, Message{
		Type: "peer_left",
		Data: leaveData,
	})
}

func (r *Room) broadcast(sender *Peer, msg Message) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	data, err := json.Marshal(msg)
	if err != nil {
		log.Printf("Failed to marshal message: %v", err)
		return
	}

	for _, peer := range r.Peers {
		if peer.ID != sender.ID {
			select {
			case peer.SendChan <- data:
			default:
				close(peer.SendChan)
				delete(r.Peers, peer.ID)
			}
		}
	}
}

func (r *Room) getPeerList(exclude *Peer) []PeerInfo {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var peers []PeerInfo
	for _, peer := range r.Peers {
		if peer.ID != exclude.ID && peer.Name != "" {
			peers = append(peers, PeerInfo{
				ID:         peer.ID,
				Name:       peer.Name,
				DeviceType: peer.DeviceType,
				IP:         peer.IP,
				Port:       peer.Port,
			})
		}
	}
	return peers
}

func (s *Server) cleanupRooms() {
	ticker := time.NewTicker(5 * time.Minute)
	for range ticker.C {
		s.roomsMu.Lock()
		for id, room := range s.rooms {
			room.mu.RLock()
			isEmpty := len(room.Peers) == 0
			age := time.Since(room.Created)
			room.mu.RUnlock()

			if isEmpty && age > 5*time.Minute {
				delete(s.rooms, id)
				log.Printf("Cleaned up empty room %s", id)
			}
		}
		s.roomsMu.Unlock()
	}
}

func main() {
	server := NewServer()

	// Start cleanup goroutine
	go server.cleanupRooms()

	// Health check endpoint
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// WebSocket endpoint
	http.HandleFunc("/ws", server.handleWebSocket)

	// Stats endpoint
	http.HandleFunc("/stats", func(w http.ResponseWriter, r *http.Request) {
		server.roomsMu.RLock()
		roomCount := len(server.rooms)
		peerCount := 0
		for _, room := range server.rooms {
			room.mu.RLock()
			peerCount += len(room.Peers)
			room.mu.RUnlock()
		}
		server.roomsMu.RUnlock()

		stats := map[string]int{
			"rooms": roomCount,
			"peers": peerCount,
		}
		
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(stats)
	})

	port := ":8081"
	log.Printf("Discovery/Signaling server starting on %s", port)
	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatal(err)
	}
}
