//
//  SampleDataManager.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import Foundation
import SwiftData
import PDFKit

class SampleDataManager {
    
    static func createSampleProject(in modelContext: ModelContext) -> Project {
        let project = Project(
            name: "Modern Office Complex",
            description: "A 12-story modern office building with sustainable design features",
            clientName: "Urban Development Corp",
            location: "Downtown Manhattan, NY"
        )
        
        modelContext.insert(project)
        
        // Create sample blueprints
        if let samplePDF1 = createSamplePDF(title: "Floor Plan - Level 1", content: "Ground Floor\nLobby, Reception, Retail Space") {
            let blueprint1 = Blueprint(
                name: "Ground Floor Plan",
                fileName: "ground-floor.pdf",
                pdfData: samplePDF1,
                pageCount: 1,
                pdfWidth: 612,
                pdfHeight: 792
            )
            blueprint1.project = project
            project.blueprints.append(blueprint1)
            modelContext.insert(blueprint1)
            
            // Add sample log entries
            let logEntry1 = LogEntry(
                title: "Main Electrical Panel",
                notes: "120V/240V panel, 200A service, located in utility room",
                category: .electrical,
                xCoordinate: 0.3,
                yCoordinate: 0.4,
                pageNumber: 1
            )
            logEntry1.blueprint = blueprint1
            blueprint1.logEntries.append(logEntry1)
            modelContext.insert(logEntry1)
            
            let logEntry2 = LogEntry(
                title: "Water Main Entry",
                notes: "3/4\" copper line from street, includes shutoff valve",
                category: .plumbing,
                xCoordinate: 0.7,
                yCoordinate: 0.6,
                pageNumber: 1
            )
            logEntry2.blueprint = blueprint1
            blueprint1.logEntries.append(logEntry2)
            modelContext.insert(logEntry2)
        }
        
        if let samplePDF2 = createSamplePDF(title: "Electrical Schematic", content: "Electrical Distribution\nPanels, Circuits, Outlets") {
            let blueprint2 = Blueprint(
                name: "Electrical Plan",
                fileName: "electrical-plan.pdf",
                pdfData: samplePDF2,
                pageCount: 1,
                pdfWidth: 612,
                pdfHeight: 792
            )
            blueprint2.project = project
            project.blueprints.append(blueprint2)
            modelContext.insert(blueprint2)
        }
        
        try? modelContext.save()
        return project
    }
    
    private static func createSamplePDF(title: String, content: String) -> Data? {
        let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Draw title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            
            let titleString = NSAttributedString(string: title, attributes: titleAttributes)
            let titleRect = CGRect(x: 50, y: 50, width: 512, height: 40)
            titleString.draw(in: titleRect)
            
            // Draw content
            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.darkGray
            ]
            
            let contentString = NSAttributedString(string: content, attributes: contentAttributes)
            let contentRect = CGRect(x: 50, y: 120, width: 512, height: 600)
            contentString.draw(in: contentRect)
            
            // Draw some architectural elements
            let context = UIGraphicsGetCurrentContext()
            context?.setStrokeColor(UIColor.blue.cgColor)
            context?.setLineWidth(2.0)
            
            // Draw a simple floor plan outline
            let roomRect = CGRect(x: 100, y: 200, width: 400, height: 300)
            context?.stroke(roomRect)
            
            // Draw some walls
            context?.move(to: CGPoint(x: 100, y: 350))
            context?.addLine(to: CGPoint(x: 300, y: 350))
            context?.strokePath()
            
            context?.move(to: CGPoint(x: 250, y: 200))
            context?.addLine(to: CGPoint(x: 250, y: 500))
            context?.strokePath()
        }
        
        return data
    }
}

// Extension to add sample data functionality (to be used in ProjectListView if needed)