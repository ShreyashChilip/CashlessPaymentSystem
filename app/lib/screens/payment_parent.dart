// import 'package:flutter/material.dart';
// import 'package:upi_india/upi_india.dart';
// import 'dart:async';

// class PaymentScreen extends StatefulWidget {
//   final double amount;
//   final String receiverName;
//   final String receiverUpiId;
//   final String transactionNote;

//   const PaymentScreen({
//     Key? key,
//     required this.amount,
//     required this.receiverName,
//     required this.receiverUpiId,
//     required this.transactionNote,
//   }) : super(key: key);

//   @override
//   _PaymentScreenState createState() => _PaymentScreenState();
// }

// class _PaymentScreenState extends State<PaymentScreen> {
//   UpiIndia _upiIndia = UpiIndia();
//   List<UpiApp>? _apps;
//   bool _isLoading = true;
//   String? _transactionStatus;
//   bool _showSuccess = false;
//   bool _showError = false;
//   String _errorMessage = '';

//   @override
//   void initState() {
//     super.initState();
//     _getApps();
//   }

//   Future<void> _getApps() async {
//     _apps = await _upiIndia.getAllUpiApps();
//     setState(() {
//       _isLoading = false;
//     });
//   }

//   Future<void> _initiateTransaction(UpiApp app) async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _showSuccess = false;
//         _showError = false;
//       });

//       final response = await _upiIndia.startTransaction(
//         app: app,
//         receiverUpiId: widget.receiverUpiId,
//         receiverName: widget.receiverName,
//         transactionRefId: DateTime.now().millisecondsSinceEpoch.toString(),
//         transactionNote: widget.transactionNote,
//         amount: widget.amount,
//       );

//       setState(() {
//         _isLoading = false;
//       });

//       // Process response
//       if (response.status == UpiPaymentStatus.SUCCESS) {
//         setState(() {
//           _transactionStatus = 'Transaction Successful';
//           _showSuccess = true;
//         });
//       } else if (response.status == UpiPaymentStatus.FAILURE) {
//         setState(() {
//           _transactionStatus = 'Transaction Failed';
//           _showError = true;
//           _errorMessage = response.error ?? 'Unknown error occurred';
//         });
//       } else if (response.status == UpiPaymentStatus.SUBMITTED) {
//         setState(() {
//           _transactionStatus = 'Transaction Submitted';
//           _showSuccess = true;
//         });
//       } else {
//         setState(() {
//           _transactionStatus = 'Transaction ${response.status}';
//           _showError = true;
//           _errorMessage = 'Payment may be pending, please check your UPI app';
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _showError = true;
//         _errorMessage = e.toString();
//       });
//     }
//   }

//   Widget _buildAppGrid() {
//     if (_apps == null || _apps!.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
//             SizedBox(height: 16),
//             Text(
//               'No UPI apps found on this device',
//               style: TextStyle(fontSize: 18),
//             ),
//           ],
//         ),
//       );
//     }

//     return GridView.count(
//       crossAxisCount: 3,
//       shrinkWrap: true,
//       physics: NeverScrollableScrollPhysics(),
//       children: _apps!.map((app) {
//         return InkWell(
//           onTap: () => _initiateTransaction(app),
//           child: Card(
//             elevation: 4,
//             margin: EdgeInsets.all(8),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Image.memory(
//                   app.icon,
//                   height: 40,
//                   width: 40,
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   app.name,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('UPI Payment'),
//         backgroundColor: Colors.purple,
//       ),
//       body: Stack(
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [Colors.purple.shade50, Colors.white],
//               ),
//             ),
//           ),
//           _isLoading
//               ? Center(child: CircularProgressIndicator())
//               : SingleChildScrollView(
//                   child: Padding(
//                     padding: const EdgeInsets.all(20.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         // Payment Details Card
//                         Card(
//                           elevation: 6,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(15),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(20.0),
//                             child: Column(
//                               children: [
//                                 Text(
//                                   'Payment Details',
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 SizedBox(height: 16),
//                                 _buildDetailRow('Amount', '₹${widget.amount}'),
//                                 _buildDetailRow('To', widget.receiverName),
//                                 _buildDetailRow('UPI ID', widget.receiverUpiId),
//                                 _buildDetailRow('Note', widget.transactionNote),
//                               ],
//                             ),
//                           ),
//                         ),
                        
//                         SizedBox(height: 24),
                        
//                         // Payment App Selection
//                         if (!_showSuccess && !_showError)
//                           Column(
//                             children: [
//                               Text(
//                                 'Select Payment Method',
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               SizedBox(height: 16),
//                               _buildAppGrid(),
//                             ],
//                           ),
                        
//                         // Success or Error UI
//                         if (_showSuccess || _showError)
//                           _buildResultCard(),
                        
//                         if (_showSuccess || _showError)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 20.0),
//                             child: ElevatedButton(
//                               onPressed: () {
//                                 setState(() {
//                                   _showSuccess = false;
//                                   _showError = false;
//                                 });
//                               },
//                               style: ElevatedButton.styleFrom(
//                                 primary: Colors.purple,
//                                 padding: EdgeInsets.symmetric(vertical: 15),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                               ),
//                               child: Text(
//                                 'Make Another Payment',
//                                 style: TextStyle(fontSize: 16),
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey[600],
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildResultCard() {
//     return Card(
//       elevation: 6,
//       color: _showSuccess ? Colors.green.shade50 : Colors.red.shade50,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           children: [
//             Icon(
//               _showSuccess ? Icons.check_circle : Icons.error,
//               size: 60,
//               color: _showSuccess ? Colors.green : Colors.red,
//             ),
//             SizedBox(height: 16),
//             Text(
//               _transactionStatus!,
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: _showSuccess ? Colors.green[700] : Colors.red[700],
//               ),
//             ),
//             if (_showError)
//               Padding(
//                 padding: const EdgeInsets.only(top: 8.0),
//                 child: Text(
//                   _errorMessage,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: Colors.red[700],
//                   ),
//                 ),
//               ),
//             SizedBox(height: 16),
//             Text(
//               'Date: ${DateTime.now().toString().substring(0, 16)}',
//               style: TextStyle(
//                 color: Colors.grey[700],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }