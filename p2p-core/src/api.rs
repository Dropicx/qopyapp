// Flutter Rust Bridge API module
use crate::peer_discovery::{PeerDiscovery as CorePeerDiscovery, DiscoveryConfig, Peer as CorePeer};
use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::Mutex;

// Flutter-compatible structures
#[derive(Debug, Clone)]
pub struct FlutterPeer {
    pub id: String,
    pub name: String,
    pub ip: String,
    pub port: u16,
    pub device_type: String,
    pub properties: HashMap<String, String>,
}

impl From<CorePeer> for FlutterPeer {
    fn from(peer: CorePeer) -> Self {
        FlutterPeer {
            id: peer.name.clone(), // Using name as ID for now
            name: peer.name,
            ip: peer.ip.to_string(),
            port: peer.port,
            device_type: peer.properties.get("device_type")
                .unwrap_or(&"unknown".to_string())
                .clone(),
            properties: peer.properties,
        }
    }
}

pub struct P2PEngine {
    discovery: Option<Arc<Mutex<CorePeerDiscovery>>>,
}

impl P2PEngine {
    pub fn new() -> Self {
        // Initialize logging
        let _ = tracing_subscriber::fmt()
            .with_env_filter("info")
            .try_init();
        
        Self {
            discovery: None,
        }
    }
    
    pub fn get_version(&self) -> String {
        "1.0.0".to_string()
    }
    
    pub async fn start_discovery(&mut self, device_name: String, device_type: String) -> Result<(), String> {
        let mut properties = HashMap::new();
        properties.insert("version".to_string(), "1.0.0".to_string());
        properties.insert("device_type".to_string(), device_type);
        
        let config = DiscoveryConfig {
            service_type: "_qopyapp._tcp.local.".to_string(),
            service_name: device_name,
            port: 8080,
            properties,
            discovery_timeout: Duration::from_secs(10),
            announce_interval: Duration::from_secs(30),
        };
        
        let discovery = CorePeerDiscovery::new(config)
            .map_err(|e| e.to_string())?;
        
        discovery.start().await
            .map_err(|e| e.to_string())?;
        
        self.discovery = Some(Arc::new(Mutex::new(discovery)));
        
        Ok(())
    }
    
    pub async fn stop_discovery(&mut self) -> Result<(), String> {
        if let Some(discovery) = &self.discovery {
            let discovery = discovery.lock().await;
            discovery.stop().await
                .map_err(|e| e.to_string())?;
        }

        self.discovery = None;
        Ok(())
    }
    
    pub async fn get_peers(&self) -> Vec<FlutterPeer> {
        if let Some(discovery) = &self.discovery {
            let discovery = discovery.lock().await;
            let peers = discovery.get_peers().await;
            peers.into_iter()
                .map(FlutterPeer::from)
                .collect()
        } else {
            Vec::new()
        }
    }
    
    pub async fn discover_peers_with_timeout(&self, timeout_seconds: u64) -> Result<Vec<FlutterPeer>, String> {
        if let Some(discovery) = &self.discovery {
            let discovery = discovery.lock().await;
            let peers = discovery.discover_peers(Some(Duration::from_secs(timeout_seconds)))
                .await
                .map_err(|e| e.to_string())?;

            Ok(peers.into_iter()
                .map(FlutterPeer::from)
                .collect())
        } else {
            Err("Discovery not started".to_string())
        }
    }
}

// Static instance for simplified FFI
static ENGINE: std::sync::OnceLock<Arc<Mutex<P2PEngine>>> = std::sync::OnceLock::new();

pub fn get_engine() -> Arc<Mutex<P2PEngine>> {
    ENGINE.get_or_init(|| {
        Arc::new(Mutex::new(P2PEngine::new()))
    }).clone()
}

// Simple FFI functions for Flutter
pub async fn init_p2p_engine() -> Result<String, String> {
    let engine = get_engine();
    let engine = engine.lock().await;
    Ok(engine.get_version())
}

pub async fn start_peer_discovery(device_name: String, device_type: String) -> Result<(), String> {
    let engine = get_engine();
    let mut engine = engine.lock().await;
    engine.start_discovery(device_name, device_type).await
}

pub async fn stop_peer_discovery() -> Result<(), String> {
    let engine = get_engine();
    let mut engine = engine.lock().await;
    engine.stop_discovery().await
}

pub async fn get_discovered_peers() -> Result<Vec<FlutterPeer>, String> {
    let engine = get_engine();
    let engine = engine.lock().await;
    Ok(engine.get_peers().await)
}
