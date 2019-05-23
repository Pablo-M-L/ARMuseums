//
//  ViewController.swift
//  ARMuseums
//
//  Created by admin on 23/05/2019.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    //guarda un diccionario.
    var paintings = [String: Painting]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        self.loadPaintingsData()
        
        self.preloadWebView()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        
        
        //cargar imagenes.
        guard let trackingInmages = ARReferenceImage.referenceImages(inGroupNamed: "Paintings", bundle: nil) else{
            fatalError("no se han podido cargar las imagens")
        }
        
        configuration.trackingImages = trackingInmages //por defecto 1
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        //sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    

    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        //scanear imagen y obtener el ancla e informacion.
        guard let imageAnchor = anchor as? ARImageAnchor else {
            return nil
        }

        guard let paintingName = imageAnchor.referenceImage.name else { return nil}
        
        guard let painting = paintings[paintingName] else { return nil}
        
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
        plane.firstMaterial?.diffuse.contents = UIColor.clear
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi/2
        
        let node = SCNNode()

        node.opacity = 0
        node.addChildNode(planeNode)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){
            SCNTransaction.animationDuration = 1
            node.opacity = 1
        }
        
        
        
        //mostrar el titulo del cuadro.
        let spacing: Float = 0.01
        
        let titleNode = textNode(for: painting.title, font: UIFont.boldSystemFont(ofSize: 10))

        //situar el titulo.
        //primero lo situamos en la esquina superior izquierda para tener una refetencia.
        titleNode.pivotToTopLeft()
        //lo desplazamos a la situacion deseada
        titleNode.position.x += Float(plane.width/2) + spacing
        titleNode.position.y += Float(plane.height/2)
        titleNode.opacity = 1
        //añadimos al planeNode.
        planeNode.addChildNode(titleNode)
        
        //añadir artista en la parte central inferior inferior.
        let artistNode = textNode(for: painting.artist, font: UIFont.systemFont(ofSize: 8))
        artistNode.pivotToTopCenter()
        artistNode.position.y -= Float(plane.height/2) + spacing
        planeNode.addChildNode(artistNode)
        
        //añadir año debajo el artista.
        let yearNode = textNode(for: painting.year, font: UIFont.systemFont(ofSize: 6))
        yearNode.pivotToTopCenter()
        yearNode.position.y = artistNode.position.y - spacing - artistNode.height
        planeNode.addChildNode(yearNode)
        
        //añadimos el webView con la wikipedia
        //obtiene la anchura del titulo para asignarlo a la webview.
        let webWidth = CGFloat(max(titleNode.width, 0.25))
        let webHeight = CGFloat((Float(plane.height) - titleNode.height) + spacing + artistNode.height + spacing + yearNode.height)
        
        let webPlane = SCNPlane(width: webWidth, height: webHeight)
        let webNode = SCNNode(geometry: webPlane)
        
        webNode.pivotToTopLeft()
        webNode.position.x += Float(plane.width/2) + spacing
        webNode.position.y = titleNode.position.y - titleNode.height - spacing
        
        planeNode.addChildNode(webNode)
        
        
        //de forma asincrona renderizamos la wikipedia.
        DispatchQueue.main.async {let width: CGFloat = 800
        let height = width / (webWidth / webHeight)
        
        let webView = UIWebView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        let request = URLRequest(url: URL(string: painting.url)!)
        
        webView.loadRequest(request)
        webPlane.firstMaterial?.diffuse.contents = webView
            
        }
      
        

        return node
    }
    
    func textNode(for str: String, font: UIFont) -> SCNNode{
        let text = SCNText(string: str, extrusionDepth: 0.0)
        text.flatness = 0.1
        text.font = font
        
        let node = SCNNode(geometry: text)
        
        //escalar el node a pequeño.
        node.scale = SCNVector3(0.002, 0.002, 0.002)
        
        return node
    }

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    //MARK: MAnage data
    func loadPaintingsData(){
        
        //localiza el fichero json y obtenemos la ruta (url)
        guard let url = Bundle.main.url(forResource: "paintings", withExtension: "json") else{
            fatalError("no hemos podido localizar la informacion de los cuadros.....")
        }
        
        //convierte el json en  datos, es decir en objetos de tipo Data.
        guard let jsonData = try? Data(contentsOf: url) else{
            fatalError("no se ha podido lerr la informacion del JSON")
        }
        
        //
        let jsonDecoder = JSONDecoder()
        
        //descodifica los datos de las pinturas, usando como clave un string y como valor un objeto de la clase Painting.self, desde el jsonData anterior.
        guard let decodedPaintings = try? jsonDecoder.decode([String: Painting].self, from: jsonData) else{
            fatalError("problemas al procesar el fichero JSON")
        }
        
        //pasamos la informacin al diccionario.
        self.paintings = decodedPaintings
    }
    
    func preloadWebView(){
        //precargamos la web para evitar retrasos.
        let preLoad = UIWebView()
        
        //añadimos una subvista.
        self.view.addSubview(preLoad)
        let request = URLRequest(url: URL(string:"google.com")!)
        preLoad.loadRequest(request)
        preLoad.removeFromSuperview()
    }
}
