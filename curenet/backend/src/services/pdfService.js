const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

/**
 * Converts a PDF file into PNG images for the Vision LLM.
 * 
 * Uses sharp (libvips) which supports PDF natively on most platforms.
 * No GraphicsMagick/ImageMagick required.
 * 
 * Falls back to returning the original PDF path if conversion fails,
 * letting the Vision LLM attempt to process the PDF directly.
 */
const convertPdfToImages = async (pdfFilePath) => {
    const outputDirectory = path.dirname(pdfFilePath);
    const baseName = path.basename(pdfFilePath, path.extname(pdfFilePath));
    
    try {
        // Sharp can render PDF pages at a given DPI (density)
        // First, try page 1 to check if PDF support is available
        const outputPath = path.join(outputDirectory, `${baseName}_page_1.png`);
        
        await sharp(pdfFilePath, { 
            page: 0,       // First page (0-indexed)
            density: 300    // 300 DPI for good OCR quality
        })
        .png()
        .toFile(outputPath);
        
        console.log(`[PDFService] Page 1 converted → ${outputPath}`);
        
        // Try to get total pages by attempting subsequent pages
        const imagePaths = [outputPath];
        let pageNum = 1;
        
        while (pageNum < 10) { // Cap at 10 pages to avoid runaway
            try {
                const nextPath = path.join(outputDirectory, `${baseName}_page_${pageNum + 1}.png`);
                await sharp(pdfFilePath, { page: pageNum, density: 300 })
                    .png()
                    .toFile(nextPath);
                imagePaths.push(nextPath);
                pageNum++;
            } catch (_) {
                // No more pages
                break;
            }
        }
        
        console.log(`[PDFService] PDF converted: ${imagePaths.length} page(s)`);
        return imagePaths;
        
    } catch (err) {
        console.error(`[PDFService] Sharp PDF conversion failed: ${err.message}`);
        
        // If sharp can't handle PDF (missing poppler/libvips PDF support),
        // return null so the worker can show a clear error
        throw new Error(
            `PDF rendering is not supported on this server. ` +
            `Please upload a screenshot or photo of the document instead.`
        );
    }
};

module.exports = {
    convertPdfToImages
};
