import SwiftUI
import UIKit
import AVFoundation
import PhotosUI

// MARK: - AVFoundation custom camera

final class CameraViewController: UIViewController {
    var onCapture: ((UIImage) -> Void)?
    var onDismiss: (() -> Void)?
    var onGallery: (() -> Void)?
    var onShutterPressed: (() -> Void)?

    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSession()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    // MARK: - Session

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(preview, at: 0)
        previewLayer = preview
    }

    // MARK: - UI

    private func setupUI() {
        let safeBottom = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.safeAreaInsets.bottom ?? 34

        let closeBtn = makeIconButton(systemName: "xmark", size: 18)
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let galleryBtn = makeIconButton(systemName: "photo.on.rectangle", size: 22)
        galleryBtn.addTarget(self, action: #selector(galleryTapped), for: .touchUpInside)

        // Кольцо добавляем ПЕРВЫМ (оно не перехватывает тачи)
        let outerRing = UIView()
        outerRing.backgroundColor = .clear
        outerRing.layer.cornerRadius = 42
        outerRing.layer.borderColor = UIColor.white.cgColor
        outerRing.layer.borderWidth = 2
        outerRing.isUserInteractionEnabled = false

        // Кнопка съёмки — поверх кольца
        let captureBtn = UIButton(type: .custom)
        captureBtn.backgroundColor = .white
        captureBtn.layer.cornerRadius = 36
        captureBtn.addTarget(self, action: #selector(captureTapped), for: .touchUpInside)

        [outerRing, captureBtn, galleryBtn, closeBtn].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            closeBtn.widthAnchor.constraint(equalToConstant: 44),
            closeBtn.heightAnchor.constraint(equalToConstant: 44),

            outerRing.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            outerRing.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(safeBottom + 20)),
            outerRing.widthAnchor.constraint(equalToConstant: 84),
            outerRing.heightAnchor.constraint(equalToConstant: 84),

            captureBtn.centerXAnchor.constraint(equalTo: outerRing.centerXAnchor),
            captureBtn.centerYAnchor.constraint(equalTo: outerRing.centerYAnchor),
            captureBtn.widthAnchor.constraint(equalToConstant: 72),
            captureBtn.heightAnchor.constraint(equalToConstant: 72),

            galleryBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(safeBottom + 28)),
            galleryBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            galleryBtn.widthAnchor.constraint(equalToConstant: 48),
            galleryBtn.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    private func makeIconButton(systemName: String, size: CGFloat) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(systemName: systemName,
                             withConfiguration: UIImage.SymbolConfiguration(pointSize: size)), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        btn.layer.cornerRadius = 22
        return btn
    }

    // MARK: - Actions

    @objc private func closeTapped() { onDismiss?() }
    @objc private func galleryTapped() { onGallery?() }

    @objc private func captureTapped() {
        guard session.isRunning else { return }
        onShutterPressed?()
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { [weak self] in self?.onCapture?(image) }
    }
}

// MARK: - SwiftUI обёртка камеры

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    let onDismiss: () -> Void
    let onGallery: () -> Void
    let onShutterPressed: () -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.onCapture = onCapture
        vc.onDismiss = onDismiss
        vc.onGallery = onGallery
        vc.onShutterPressed = onShutterPressed
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

// MARK: - Gallery (PHPickerViewController)

struct GalleryPickerView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: GalleryPickerView
        init(_ parent: GalleryPickerView) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else { parent.onDismiss(); return }
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                DispatchQueue.main.async {
                    if let image = object as? UIImage { self.parent.onCapture(image) }
                    else { self.parent.onDismiss() }
                }
            }
        }
    }
}

// MARK: - CameraFlowView — камера уезжает вниз, открывая PhotoReviewView

struct CameraFlowView: View {
    let onDismiss: () -> Void
    var onItemSaved: ((UIImage, Folder) -> Void)? = nil

    @State private var capturedImage: UIImage? = nil
    @State private var cameraOffset: CGFloat = 0
    @State private var cameraSlid = false
    @State private var showGallery = false

    private var screenH: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .keyWindow?.bounds.height ?? 844
    }

    var body: some View {
        ZStack {
            // Белый фон — виден сразу после нажатия затвора (до прихода изображения)
            if cameraSlid {
                Color.white.ignoresSafeArea()
                    .overlay(DotPattern().ignoresSafeArea())
            }

            // Review под камерой — рендерится когда есть фото
            if let image = capturedImage {
                PhotoReviewView(originalImage: image, onDismiss: onDismiss, onItemSaved: onItemSaved)
                    .ignoresSafeArea()
                    .allowsHitTesting(true)
            }

            // Камера — уезжает вниз при съёмке
            CameraView(
                onCapture: { image in
                    capturedImage = image
                    // Для галереи — нужно тоже сдвинуть камеру
                    if !cameraSlid {
                        cameraSlid = true
                        withAnimation(.easeInOut(duration: 0.45)) { cameraOffset = screenH }
                    }
                },
                onDismiss: onDismiss,
                onGallery: { showGallery = true },
                onShutterPressed: {
                    cameraSlid = true
                    withAnimation(.easeInOut(duration: 0.45)) { cameraOffset = screenH }
                }
            )
            .ignoresSafeArea()
            .offset(y: cameraOffset)
            .allowsHitTesting(!cameraSlid)
        }
        .sheet(isPresented: $showGallery) {
            GalleryPickerView(
                onCapture: { image in
                    showGallery = false
                    capturedImage = image
                    withAnimation(.easeInOut(duration: 0.45)) {
                        cameraOffset = screenH
                    }
                },
                onDismiss: { showGallery = false }
            )
            .ignoresSafeArea()
        }
    }
}
