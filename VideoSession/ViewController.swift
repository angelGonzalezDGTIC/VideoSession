//
//  ViewController.swift
//  VideoSession
//
//  Created by Ángel González on 11/11/22.
//

import UIKit
import AVFoundation
import MessageUI

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, AVCaptureMetadataOutputObjectsDelegate, MFMailComposeViewControllerDelegate {
    
    func enviarCorreo(_ codigoAenviar: String) {
        // primero hay que detectar que SI se pueden enviar correos (debe estar configurada una cuenta en la aplicación de correo del dispositivo)
        if MFMailComposeViewController.canSendMail() {
            let mcvc = MFMailComposeViewController()
            mcvc.mailComposeDelegate = self
            mcvc.setToRecipients(["jan.zelaznog@gmail.com"])
            mcvc.setSubject("Correo enviado desde el app mas bonita del mundo mundial")
            mcvc.setMessageBody("<strong>Encontré un código! " + codigoAenviar + "</strong>", isHTML: true)
            self.present(mcvc, animated: true)
        }
    }
    
    func compartir (_ codigoAenviar: String) {
        let elementos = [codigoAenviar, URL(string: "https://www.unam.mx")!] as [Any]
        let avc = UIActivityViewController(activityItems: elementos, applicationActivities:nil)
        self.present(avc, animated: true)
    }
    
    // MARK: - Métodos de los protocolos
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        // deberíamos hacer algo si no se pudo enviar?
        //...
        // cerramos el controller de correo
        controller.dismiss(animated: true)
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // identificamos si hay un objeto
        if let objetoLeido = metadataObjects.first {
            // obtenemos el valor (contenido) del objeto
            guard let codigoLeido = objetoLeido as? AVMetadataMachineReadableCodeObject
            else { return }
            guard let cadena = codigoLeido.stringValue else { return }
            let ac = UIAlertController(title:"CODIGO ENCONTRADO", message:cadena, preferredStyle: .alert)
            let action = UIAlertAction(title: "Enviar por mail", style: .default) {
                action in
                // enviar por correo el código detectado
                self.enviarCorreo(cadena)
            }
            ac.addAction(action)
            let action2 = UIAlertAction(title: "Compartir", style:.destructive) {
                action2 in
                self.compartir(cadena)
            }
            ac.addAction(action2)
            self.present(ac, animated: true)
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error == nil {
            // si se grabó correctamente el video
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
            // si quisieramos hacer algo con el video, Ej. enviarlo a un webservice
            let bytes = try? Data(contentsOf: outputFileURL)
            
        }
        else {
            // TODO: avisar al usuario
            print ("so sorry...")
        }
    }
    
    let btnCamara = UIButton(type: .custom)
    var vSesion:AVCaptureSession!
    var vFlujo:AVCaptureMovieFileOutput!
    
    var capturando: Bool = false {
        didSet { // le asignamos un closure a la variable para que lo ejecute cuando sea asignado su valor
            if capturando {
                btnCamara.setImage(UIImage(systemName:"pause.fill"), for: .normal)
            }
            else {
                btnCamara.setImage(UIImage(systemName:"video.fill"), for: .normal)
            }
        }
    }
    
    @objc func pausarGrabar () {
        capturando = !capturando
        if capturando {
            // guardar el video en una ubicación temporal
            // para trabajar con archivos tenemos 3 ubicaciones:
            // 1.- el Bundle de la app (solo lectura
            // 2.- la carpeta Documents (lectura y escritura) se respalda en iCloud
            // 3.- la carpeta Library (lectura y escritura) NO se respalda en iCloud
            // encontrar la carpeta de "Library"
            let paths = FileManager.default.urls(for:.libraryDirectory, in:.userDomainMask)
            let rutaAlarchivo = paths.first?.appendingPathComponent("temp.mp4")
            vFlujo = AVCaptureMovieFileOutput()
            if vSesion.canAddOutput(vFlujo) {
                vSesion.addOutput(vFlujo)
            }
            vFlujo.startRecording(to: rutaAlarchivo!, recordingDelegate: self)
        }
        else {
            // terminó de capturar, mover el video capturado a la librería
            vFlujo.stopRecording()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnCamara.setImage(UIImage(systemName:"video.fill"), for: .normal)
        btnCamara.frame = CGRect(x: self.view.center.x, y: self.view.frame.height - 60, width: 60, height: 40)
        btnCamara.addTarget(self, action:#selector(pausarGrabar), for:.touchUpInside)
        // instanciamos el objeto sesion de captura
        vSesion = AVCaptureSession()
        // comprobamos si el telefono tiene un dispositivo de captura de video
        guard let vDispositivo = AVCaptureDevice.default(for: .video) else { return }
        do {
            // si hay un dispositivo de captura de video, entonces intentamos agregarlo a la sesión
            let entradaVideo = try AVCaptureDeviceInput(device: vDispositivo)
            if vSesion.canAddInput(entradaVideo) {
                vSesion.addInput(entradaVideo)
            }
            // agregamos un layer para mostrar lo que esta "viendo" la cámara
            let videoLayer = AVCaptureVideoPreviewLayer(session: vSesion)
            videoLayer.frame = self.view.bounds
            self.view.layer.addSublayer(videoLayer)
            vSesion.startRunning()
            
            // Para detectar códigos:
            let metadatos = AVCaptureMetadataOutput()
            if vSesion.canAddOutput(metadatos) {
                vSesion.addOutput(metadatos)
                metadatos.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadatos.metadataObjectTypes = [.qr]
            }
            
            
        }
        catch {
            return
        }
        self.view.addSubview(btnCamara)
        
    }


}

