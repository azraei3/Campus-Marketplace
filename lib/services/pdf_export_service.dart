import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reporting_service.dart';

class PdfExportService {
  Future<void> generateAndSharePdf(UserReportData data) async {
    final pdf = pw.Document();
    final user = FirebaseAuth.instance.currentUser;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Campus Marketplace', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple)),
                      pw.SizedBox(height: 4),
                      pw.Text('Activity & Performance Report', style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Date: ${DateTime.now().toLocal().toString().split(' ')[0]}'),
                      pw.Text('User: ${user?.displayName ?? 'Verified Student'}'),
                      pw.Text(user?.email ?? '', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    ]
                  )
                ]
              ),
              pw.Divider(thickness: 2, color: PdfColors.deepPurple300),
              pw.SizedBox(height: 20),

              // Overview Section
              pw.Text('Account Overview', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _buildStatRow('Total Listings Created', data.totalListings.toString()),
              _buildStatRow('Active Listings', data.activeListings.toString()),
              _buildStatRow('Total Views Received', data.totalViews.toString()),
              _buildStatRow('Total Saves/Favorites', data.totalSaves.toString()),
              _buildStatRow('Requests Sent (Buying)', data.totalRequestsSent.toString()),
              _buildStatRow('Requests Received (Selling)', data.totalRequestsReceived.toString()),
              
              pw.SizedBox(height: 30),

              // Category Breakdown
              pw.Text('Listings by Category', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...data.categoryDistribution.entries.map((e) => _buildStatRow(e.key, e.value.toString())),

              pw.Spacer(),
              
              // Footer
              pw.Divider(),
              pw.Center(
                child: pw.Text('Generated securely by Campus Marketplace AI-Reporting System', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'CampusMarketplace_Report.pdf',
    );
  }

  pw.Widget _buildStatRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
