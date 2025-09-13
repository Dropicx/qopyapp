use qopyapp::{PeerDiscovery, DiscoveryConfig};
use std::collections::HashMap;
use std::time::Duration;
use tracing::{info, error};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize tracing
    tracing_subscriber::fmt::init();
    
    // Create configuration
    let mut properties = HashMap::new();
    properties.insert("version".to_string(), "1.0.0".to_string());
    properties.insert("device_type".to_string(), "laptop".to_string());
    
    let config = DiscoveryConfig {
        service_type: "_qopyapp._tcp.local.".to_string(),
        service_name: "my-device".to_string(),
        port: 8080,
        properties,
        discovery_timeout: Duration::from_secs(10),
        announce_interval: Duration::from_secs(30),
    };
    
    // Create peer discovery instance
    let discovery = PeerDiscovery::new(config)?;
    
    // Subscribe to events
    let mut event_receiver = discovery.subscribe();
    
    // Start the discovery service
    discovery.start().await?;
    info!("Peer discovery started");
    
    // Spawn a task to handle events
    let _discovery_clone = discovery.clone();
    tokio::spawn(async move {
        while let Ok(event) = event_receiver.recv().await {
            match event {
                qopyapp::PeerEvent::PeerDiscovered(peer) => {
                    info!("New peer discovered: {} at {}:{}", 
                          peer.name, peer.ip, peer.port);
                }
                qopyapp::PeerEvent::PeerLost(peer) => {
                    info!("Peer lost: {}", peer.name);
                }
                qopyapp::PeerEvent::ServiceStarted => {
                    info!("Service started");
                }
                qopyapp::PeerEvent::ServiceStopped => {
                    info!("Service stopped");
                }
                qopyapp::PeerEvent::Error(err) => {
                    error!("Discovery error: {}", err);
                }
            }
        }
    });
    
    // Discover peers
    info!("Discovering peers...");
    let peers = discovery.discover_peers(Some(Duration::from_secs(5))).await?;
    
    info!("Found {} peers:", peers.len());
    for peer in &peers {
        info!("  - {}: {}:{}", peer.name, peer.ip, peer.port);
        for (key, value) in &peer.properties {
            info!("    {}: {}", key, value);
        }
    }
    
    // Keep running for a while to see dynamic updates
    info!("Running for 30 seconds to see dynamic updates...");
    tokio::time::sleep(Duration::from_secs(30)).await;
    
    // Stop the service
    discovery.stop().await?;
    info!("Peer discovery stopped");
    
    Ok(())
}
