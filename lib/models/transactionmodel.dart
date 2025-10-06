import 'package:intl/intl.dart';

class Transactionmodel {
  String customerName;
  int itemCount;
  int totalAmount;
  DateTime timePurchased;

  Transactionmodel({
    required this.customerName,
    required this.itemCount,
    required this.totalAmount,
    DateTime? timePurchased, 
  }) : timePurchased = timePurchased ?? DateTime.now();

  String get formattedTime {
    return DateFormat('h:mm a').format(timePurchased);
  }

  static List<Transactionmodel> getTransaction() {
    List<Transactionmodel> transaction = [
      Transactionmodel(
        customerName: 'Louis',
        itemCount: 3,
        totalAmount: 230,
      ),
      Transactionmodel(
        customerName: 'Maurice',
        itemCount: 5,
        totalAmount: 500,
      ),
      Transactionmodel(
        customerName: 'Rafael',
        itemCount: 2,
        totalAmount: 170,
      ),
      Transactionmodel(
        customerName: 'Jabez',
        itemCount: 10,
        totalAmount: 800,
      ),
    ];

    return transaction;
  }
}
