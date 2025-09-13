use thiserror::Error;

#[derive(Error, Debug, Clone)]
pub enum PeerDiscoveryError {
    #[error("mDNS service error: {0}")]
    MdnsError(String),
    
    #[error("Network interface error: {0}")]
    NetworkInterfaceError(String),
    
    #[error("Service registration failed: {0}")]
    ServiceRegistrationFailed(String),
    
    #[error("Service discovery failed: {0}")]
    ServiceDiscoveryFailed(String),
    
    #[error("Invalid service type: {0}")]
    InvalidServiceType(String),
    
    #[error("Timeout waiting for discovery: {0}")]
    DiscoveryTimeout(String),
    
    #[error("IO error: {0}")]
    IoError(String),
}

impl From<mdns_sd::Error> for PeerDiscoveryError {
    fn from(err: mdns_sd::Error) -> Self {
        PeerDiscoveryError::MdnsError(err.to_string())
    }
}

impl From<std::io::Error> for PeerDiscoveryError {
    fn from(err: std::io::Error) -> Self {
        PeerDiscoveryError::IoError(err.to_string())
    }
}
