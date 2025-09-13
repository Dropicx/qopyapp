use crate::error::PeerDiscoveryError;
use anyhow::Result;
use mdns_sd::{ServiceDaemon, ServiceEvent, ServiceInfo};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::net::IpAddr;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::{broadcast, RwLock};
use tokio::time::sleep;
use tracing::{debug, error, info, warn};

#[cfg(not(target_os = "android"))]
use get_if_addrs;

/// Represents a discovered peer with its network information
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Peer {
    pub name: String,
    pub ip: IpAddr,
    pub port: u16,
    pub service_type: String,
    pub properties: HashMap<String, String>,
}

/// Configuration for the peer discovery service
#[derive(Debug, Clone)]
pub struct DiscoveryConfig {
    pub service_type: String,
    pub service_name: String,
    pub port: u16,
    pub properties: HashMap<String, String>,
    pub discovery_timeout: Duration,
    pub announce_interval: Duration,
}

impl Default for DiscoveryConfig {
    fn default() -> Self {
        Self {
            service_type: "_qopyapp._tcp.local.".to_string(),
            service_name: "qopyapp-device".to_string(),
            port: 8080,
            properties: HashMap::new(),
            discovery_timeout: Duration::from_secs(10),
            announce_interval: Duration::from_secs(30),
        }
    }
}

/// Main peer discovery service that handles mDNS broadcasting and discovery
pub struct PeerDiscovery {
    daemon: ServiceDaemon,
    config: DiscoveryConfig,
    discovered_peers: Arc<RwLock<HashMap<String, Peer>>>,
    peer_sender: broadcast::Sender<PeerEvent>,
    is_running: Arc<RwLock<bool>>,
}

impl Clone for PeerDiscovery {
    fn clone(&self) -> Self {
        Self {
            daemon: self.daemon.clone(),
            config: self.config.clone(),
            discovered_peers: self.discovered_peers.clone(),
            peer_sender: self.peer_sender.clone(),
            is_running: self.is_running.clone(),
        }
    }
}

/// Events that can be emitted by the peer discovery service
#[derive(Debug, Clone)]
pub enum PeerEvent {
    PeerDiscovered(Peer),
    PeerLost(Peer),
    ServiceStarted,
    ServiceStopped,
    Error(PeerDiscoveryError),
}

impl PeerDiscovery {
    /// Create a new peer discovery instance
    pub fn new(config: DiscoveryConfig) -> Result<Self, PeerDiscoveryError> {
        let daemon = ServiceDaemon::new()?;
        let (peer_sender, _) = broadcast::channel(100);
        
        Ok(Self {
            daemon,
            config,
            discovered_peers: Arc::new(RwLock::new(HashMap::new())),
            peer_sender,
            is_running: Arc::new(RwLock::new(false)),
        })
    }

    /// Start the peer discovery service
    pub async fn start(&self) -> Result<(), PeerDiscoveryError> {
        let mut is_running = self.is_running.write().await;
        if *is_running {
            return Ok(());
        }
        *is_running = true;
        drop(is_running);

        info!("Starting peer discovery service");
        
        // Register our own service
        self.register_service().await?;
        
        // Start discovery
        self.start_discovery().await?;
        
        let _ = self.peer_sender.send(PeerEvent::ServiceStarted);
        info!("Peer discovery service started successfully");
        
        Ok(())
    }

    /// Stop the peer discovery service
    pub async fn stop(&self) -> Result<(), PeerDiscoveryError> {
        let mut is_running = self.is_running.write().await;
        if !*is_running {
            return Ok(());
        }
        *is_running = false;
        drop(is_running);

        info!("Stopping peer discovery service");
        
        // Unregister our service
        if let Err(e) = self.daemon.unregister(&self.config.service_name) {
            warn!("Failed to unregister service: {}", e);
        }
        
        // Clear discovered peers
        {
            let mut peers = self.discovered_peers.write().await;
            peers.clear();
        }
        
        let _ = self.peer_sender.send(PeerEvent::ServiceStopped);
        info!("Peer discovery service stopped");
        
        Ok(())
    }

    /// Get a receiver for peer events
    pub fn subscribe(&self) -> broadcast::Receiver<PeerEvent> {
        self.peer_sender.subscribe()
    }

    /// Get all currently discovered peers
    pub async fn get_peers(&self) -> Vec<Peer> {
        let peers = self.discovered_peers.read().await;
        peers.values().cloned().collect()
    }

    /// Get a specific peer by name
    pub async fn get_peer(&self, name: &str) -> Option<Peer> {
        let peers = self.discovered_peers.read().await;
        peers.get(name).cloned()
    }

    /// Discover peers with a timeout
    pub async fn discover_peers(&self, timeout_duration: Option<Duration>) -> Result<Vec<Peer>, PeerDiscoveryError> {
        let timeout_duration = timeout_duration.unwrap_or(self.config.discovery_timeout);
        
        info!("Starting peer discovery with timeout: {:?}", timeout_duration);
        
        // Start discovery if not already running
        if !*self.is_running.read().await {
            self.start().await?;
        }
        
        // Wait for discovery timeout
        sleep(timeout_duration).await;
        
        let peers = self.get_peers().await;
        info!("Discovered {} peers", peers.len());
        
        Ok(peers)
    }

    /// Register our own service for other peers to discover
    async fn register_service(&self) -> Result<(), PeerDiscoveryError> {
        let service_info = ServiceInfo::new(
            &self.config.service_type,
            &self.config.service_name,
            &format!("{}.local.", self.config.service_name),
            self.config.ip_address().await?,
            self.config.port,
            None, // No properties for now
        )?;
        
        self.daemon.register(service_info)?;
        info!("Registered service: {} on port {}", self.config.service_name, self.config.port);
        
        Ok(())
    }

    /// Start discovering other peers
    async fn start_discovery(&self) -> Result<(), PeerDiscoveryError> {
        let daemon = self.daemon.clone();
        let service_type = self.config.service_type.clone();
        let discovered_peers = self.discovered_peers.clone();
        let peer_sender = self.peer_sender.clone();
        
        tokio::spawn(async move {
            let receiver = daemon.browse(&service_type).map_err(|e| {
                error!("Failed to start browsing: {}", e);
                PeerDiscoveryError::ServiceDiscoveryFailed(e.to_string())
            })?;
            
            info!("Started browsing for service type: {}", service_type);
            
            while let Ok(event) = receiver.recv_async().await {
                if let Err(e) = Self::handle_service_event(event, &discovered_peers, &peer_sender).await {
                    error!("Error handling service event: {}", e);
                    let _ = peer_sender.send(PeerEvent::Error(e));
                }
            }
            
            Ok::<(), PeerDiscoveryError>(())
        });
        
        Ok(())
    }

    /// Handle incoming service events (peer discovered/lost)
    async fn handle_service_event(
        event: ServiceEvent,
        discovered_peers: &Arc<RwLock<HashMap<String, Peer>>>,
        peer_sender: &broadcast::Sender<PeerEvent>,
    ) -> Result<(), PeerDiscoveryError> {
        match event {
            ServiceEvent::ServiceResolved(info) => {
                let peer = Peer {
                    name: info.get_fullname().to_string(),
                    ip: info.get_addresses()
                        .iter()
                        .find(|addr| addr.is_ipv4())
                        .copied()
                        .ok_or_else(|| PeerDiscoveryError::NetworkInterfaceError("No IPv4 address found".to_string()))?,
                    port: info.get_port(),
                    service_type: info.get_type().to_string(),
                    properties: info.get_properties().iter()
                        .filter_map(|prop| {
                            prop.val().map(|val| {
                                (prop.key().to_string(), String::from_utf8_lossy(val).to_string())
                            })
                        })
                        .collect(),
                };
                
                debug!("Peer discovered: {:?}", peer);
                
                // Add to discovered peers
                {
                    let mut peers = discovered_peers.write().await;
                    peers.insert(peer.name.clone(), peer.clone());
                }
                
                let _ = peer_sender.send(PeerEvent::PeerDiscovered(peer));
            }
            ServiceEvent::ServiceRemoved(_, fullname) => {
                debug!("Peer lost: {}", fullname);
                
                // Remove from discovered peers
                let removed_peer = {
                    let mut peers = discovered_peers.write().await;
                    peers.remove(&fullname)
                };
                
                if let Some(peer) = removed_peer {
                    let _ = peer_sender.send(PeerEvent::PeerLost(peer));
                }
            }
            _ => {
                debug!("Unhandled service event: {:?}", event);
            }
        }
        
        Ok(())
    }
}

impl DiscoveryConfig {
    /// Get the local IP address for service registration
    async fn ip_address(&self) -> Result<IpAddr, PeerDiscoveryError> {
        #[cfg(not(target_os = "android"))]
        {
            // Try to get the first available IPv4 address
            for interface in get_if_addrs::get_if_addrs().map_err(|e| {
                PeerDiscoveryError::NetworkInterfaceError(e.to_string())
            })? {
                if interface.is_loopback() {
                    continue;
                }

                if let std::net::IpAddr::V4(ipv4) = interface.ip() {
                    return Ok(IpAddr::V4(ipv4));
                }
            }

            Err(PeerDiscoveryError::NetworkInterfaceError(
                "No suitable network interface found".to_string()
            ))
        }

        #[cfg(target_os = "android")]
        {
            // On Android, use a default IP or try to detect it differently
            // For now, use a placeholder that will be replaced by actual IP
            Ok(IpAddr::V4(std::net::Ipv4Addr::new(192, 168, 1, 100)))
        }
    }
}

/// Utility function to get all available network interfaces
pub async fn get_network_interfaces() -> Result<Vec<NetworkInterface>, PeerDiscoveryError> {
    let mut result = Vec::new();

    #[cfg(not(target_os = "android"))]
    {
        let interfaces = get_if_addrs::get_if_addrs().map_err(|e| {
            PeerDiscoveryError::NetworkInterfaceError(e.to_string())
        })?;

        for interface in interfaces {
            result.push(NetworkInterface {
                name: interface.name.clone(),
                ip: interface.ip(),
                is_loopback: interface.is_loopback(),
            });
        }
    }

    #[cfg(target_os = "android")]
    {
        // Return a default interface for Android
        result.push(NetworkInterface {
            name: "wlan0".to_string(),
            ip: IpAddr::V4(std::net::Ipv4Addr::new(192, 168, 1, 100)),
            is_loopback: false,
        });
    }

    Ok(result)
}

/// Represents a network interface
#[derive(Debug, Clone)]
pub struct NetworkInterface {
    pub name: String,
    pub ip: IpAddr,
    pub is_loopback: bool,
}

#[cfg(test)]
mod tests {
    use super::*;
    use tokio::time::sleep;

    #[tokio::test]
    async fn test_peer_discovery_creation() {
        let config = DiscoveryConfig::default();
        let discovery = PeerDiscovery::new(config);
        assert!(discovery.is_ok());
    }

    #[tokio::test]
    async fn test_peer_discovery_start_stop() {
        let config = DiscoveryConfig::default();
        let discovery = PeerDiscovery::new(config).unwrap();
        
        // Start the service
        assert!(discovery.start().await.is_ok());
        
        // Wait a bit
        sleep(Duration::from_millis(100)).await;
        
        // Stop the service
        assert!(discovery.stop().await.is_ok());
    }

    #[tokio::test]
    async fn test_peer_discovery_subscription() {
        let config = DiscoveryConfig::default();
        let discovery = PeerDiscovery::new(config).unwrap();
        
        let mut receiver = discovery.subscribe();
        
        // Start the service
        discovery.start().await.unwrap();
        
        // Should receive ServiceStarted event
        let event = receiver.recv().await.unwrap();
        assert!(matches!(event, PeerEvent::ServiceStarted));
        
        discovery.stop().await.unwrap();
    }

    #[tokio::test]
    async fn test_peer_discovery_get_peers() {
        let config = DiscoveryConfig::default();
        let discovery = PeerDiscovery::new(config).unwrap();
        
        // Initially no peers
        let peers = discovery.get_peers().await;
        assert!(peers.is_empty());
        
        discovery.start().await.unwrap();
        sleep(Duration::from_millis(100)).await;
        discovery.stop().await.unwrap();
    }
}
