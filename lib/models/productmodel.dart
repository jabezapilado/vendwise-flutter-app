class Productmodel {
  String prodImage;
  String productName;
  String productDesc;
  int priceM;
  int priceL;
  String prodType;

  Productmodel({
    required this.productName,
    required this.productDesc,
    required this.priceM,
    required this.priceL,
    required this.prodImage,
    required this.prodType
  });

  static List<Productmodel> getProduct() {
    List<Productmodel> product = [
      Productmodel(
        prodImage: 'assets/images/Classic_Milk_Tea.jpg',
        productName: 'Classic Milk Tea',
        productDesc:
            'The timeless blend of black tea and creamy milk, smooth and perfectly balanced',
        priceM: 90,
        priceL: 110,
        prodType: 'Drinks'
      ),
      Productmodel(
        prodImage: 'assets/images/Wintermelon_Milk_Tea.jpg',
        productName: 'Wintermelon Milk Tea',
        productDesc: 'A refreshing sweet tea with a light honey-like taste and creamy finish.',
        priceM: 95,
        priceL: 115,
        prodType: 'Drinks'
      ),
      Productmodel(
        prodImage: 'assets/images/Gardenia_Bread.jpg',
        productName: 'Gardenia Bread',
        productDesc: 'A bread',
        priceM: 120,
        priceL: 0,
        prodType: 'Foods'
      ),
      Productmodel(
        prodImage: 'assets/images/French_fries.jpg',
        productName: 'Fries',
        productDesc: 'On-the-go or flavored options: Potato Corner offers affordable specialty fries from ₱35 onwards.',
        priceM: 35,
        priceL: 0,
        prodType: 'Foods'
      ),
      //Newly ADDED
      Productmodel(
        prodImage: 'assets/images/Thai_Milk_Tea.jpg',
        productName: 'Thai Milk Tea',
        productDesc: 'On-the-go or flavored options: Potato Corner offers affordable specialty fries from ₱35 onwards.',
        priceM: 95,
        priceL: 115,
        prodType: 'Drinks'
      ),
      Productmodel(
        prodImage: 'assets/images/Nachos.jpg',
        productName: 'Nachos',
        productDesc: 'On-the-go or flavored options: Potato Corner offers affordable specialty fries from ₱35 onwards.',
        priceM: 35,
        priceL: 0,
        prodType: 'Foods'
      ),
      Productmodel(
        prodImage: 'assets/images/Black_Pearl.jpg',
        productName: 'Black Pearl',
        productDesc: 'On-the-go or flavored options: Potato Corner offers affordable specialty fries from ₱35 onwards.',
        priceM: 35,
        priceL: 0,
        prodType: 'Add-On'
      ),
      Productmodel(
        prodImage: 'assets/images/Nata_de_Coco.jpg',
        productName: 'Nata de Coco',
        productDesc: 'On-the-go or flavored options: Potato Corner offers affordable specialty fries from ₱35 onwards.',
        priceM: 35,
        priceL: 0,
        prodType: 'Add-On'
      ),
      Productmodel(
        prodImage: 'assets/images/Cheese_Foam.jpg',
        productName: 'Cheese Foam',
        productDesc: 'On-the-go or flavored options: Potato Corner offers affordable specialty fries from ₱35 onwards.',
        priceM: 35,
        priceL: 0,
        prodType: 'Add-On'
      ),
    ];

    return product;
  }
}
