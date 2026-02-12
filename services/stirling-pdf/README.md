# Stirling PDF - PDF Tools

## Overview
Stirling PDF is a self-hosted web application that provides a suite of PDF manipulation tools.

## Configuration
- **Domain**: https://pdf.orfel.de
- **Internal Port**: 11013
- **User**: Jannik

## Available Tools
- Merge PDFs
- Split PDFs
- Rotate, scale, and crop pages
- Add watermarks
- Add/remove passwords
- Compress PDFs
- Extract images from PDFs
- Convert PDFs to/from images
- OCR (optical character recognition)
- Sign PDFs
- Add page numbers

## First Run
1. Navigate to https://pdf.orfel.de
2. Start using the available PDF tools
3. No account needed (read-only mode)

## Data Storage
- Temporary files: /mnt/Jannik-Cloud-Volume-01/stirling-pdf

## Security Features
- No files stored permanently
- Security scanning enabled
- Input validation
- Secure defaults

## Supported Formats
- Input: PDF, images (JPG, PNG, etc.)
- Output: PDF, images, text (OCR)

## Logs
```bash
docker logs stirling-pdf
```

## Use Cases
- Document processing pipelines
- Batch PDF operations
- OCR for document digitization
- PDF compression for cloud storage
