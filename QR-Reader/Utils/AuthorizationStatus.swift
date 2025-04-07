import AVFoundation
import Photos

struct AuthorizationStatus {
    enum AuthorizationState {
        case granted
        case denied
    }
    
    private init() { }
    
    static func checkCameraAndPhotoLibraryAuthorizationStatus(completion: @escaping (AuthorizationState) -> Void) {
        var cameraAuthorized = false
        var photoLibraryAuthorized = false
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraStatus {
        case .authorized:
            cameraAuthorized = true
            dispatchGroup.leave()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                cameraAuthorized = granted
                dispatchGroup.leave()
            }
        case .denied, .restricted:
            cameraAuthorized = false
            dispatchGroup.leave()
        @unknown default:
            cameraAuthorized = false
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        let photoStatus = PHPhotoLibrary.authorizationStatus()
        switch photoStatus {
        case .authorized, .limited:
            photoLibraryAuthorized = true
            dispatchGroup.leave()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                photoLibraryAuthorized = (status == .authorized || status == .limited)
                dispatchGroup.leave()
            }
        case .denied, .restricted:
            photoLibraryAuthorized = false
            dispatchGroup.leave()
        @unknown default:
            photoLibraryAuthorized = false
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            let state: AuthorizationState = cameraAuthorized && photoLibraryAuthorized ? .granted : .denied
            completion(state)
        }
    }
}
