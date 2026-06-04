const fs = require('fs');
const path = require('path');

/**
 * Handles PDF files for the Vision LLM pipeline.
 * 
 * Strategy: Convert PDF to base64 data URI that Vision LLMs can consume directly.
 * Gemini, Groq, and Nvidia NIM all support base64-encoded images/documents.
 * 
 * If sharp supports PDF (macOS with poppler), render to PNG at 300 DPI.
 * Otherwise, send the raw PDF bytes as base64 — most modern Vision LLMs 
 * can read PDFs natively.
 * 
 * NO system dependencies required (no GraphicsMagick, no ImageMagick, no poppler).
 */
const convertPdfToImages = async (pdfFilePath) => {
    const outputDirectory = path.dirname(pdfFilePath);
    const baseName = path.basename(pdfFilePath, path.extname(pdfFilePath));
    
    // Strategy 1: Try sharp PDF rendering (works on macOS, may fail on Linux)
    try {
        const sharp = require('sharp');
        const outputPath = path.join(outputDirectory, `${baseName}_page_1.png`);
        
        await sharp(pdfFilePath, { page: 0, density: 300 })
            .png()
            .toFile(outputPath);
        
        console.log(`[PDFService] Sharp PDF render succeeded → ${outputPath}`);
        
        const imagePaths = [outputPath];
        let pageNum = 1;
        while (pageNum < 10) {
            try {
                const nextPath = path.join(outputDirectory, `${baseName}_page_${pageNum + 1}.png`);
                await sharp(pdfFilePath, { page: pageNum, density: 300 })
                    .png()
                    .toFile(nextPath);
                imagePaths.push(nextPath);
                pageNum++;
            } catch (_) { break; }
        }
        
        console.log(`[PDFService] Converted ${imagePaths.length} page(s) via sharp`);
        return imagePaths;
    } catch (sharpErr) {
        console.warn(`[PDFService] Sharp PDF not supported: ${sharpErr.message}`);
    }
    
    // Strategy 2: Convert PDF to a PNG screenshot using pdf-image workaround
    // Read the PDF, encode as base64, and create a wrapper image file
    // that the Vision LLM can process
    try {
        console.log('[PDFService] Using base64 PDF passthrough for Vision LLM...');
        
        // Create a marker file that tells the Vision LLM service 
        // to send this as a PDF document, not an image
        const pdfBytes = fs.readFileSync(pdfFilePath);
        const base64Pdf = pdfBytes.toString('base64');
        
        // Write a JSON sidecar that the vision service can read
        const sidecarPath = path.join(outputDirectory, `${baseName}.pdf.json`);
        fs.writeFileSync(sidecarPath, JSON.stringify({
            type: 'pdf',
            base64: base64Pdf,
            mimeType: 'application/pdf',
            originalPath: pdfFilePath,
            pages: 'all'
        }));
        
        console.log(`[PDFService] PDF base64 sidecar created (${(pdfBytes.length / 1024).toFixed(0)} KB) → ${sidecarPath}`);
        
        // Return the sidecar path — the vision service will detect .pdf.json 
        // and handle it appropriately
        return [sidecarPath];
    } catch (err) {
        throw new Error(
            `PDF processing failed: ${err.message}. ` +
            `Please upload a screenshot or photo of the document instead.`
        );
    }
};

module.exports = {
    convertPdfToImages
};
