import 'package:flutter/material.dart';
import 'dart:io';

class PartDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> sparePart;
  final File? uploadedImage;

  const PartDetailsScreen({
    Key? key,
    required this.sparePart,
    this.uploadedImage,
  }) : super(key: key);

  @override
  State<PartDetailsScreen> createState() => _PartDetailsScreenState();
}

class _PartDetailsScreenState extends State<PartDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _quantity = 1;
  int _selectedImageIndex = 0;
  bool _isFavorite = false;

  // Mock data for reviews
  final List<Map<String, dynamic>> _reviews = [
    {
      'user': 'John D.',
      'rating': 5,
      'date': '2 weeks ago',
      'comment': 'Perfect fit for my tractor. Great quality!',
      'verified': true,
    },
    {
      'user': 'Sarah M.',
      'rating': 4,
      'date': '1 month ago',
      'comment': 'Good product but shipping took longer than expected.',
      'verified': true,
    },
    {
      'user': 'Mike R.',
      'rating': 5,
      'date': '2 months ago',
      'comment': 'Excellent quality. Highly recommended.',
      'verified': false,
    },
  ];

  // Mock data for suppliers
  final List<Map<String, dynamic>> _suppliers = [
    {
      'name': 'AgriParts Direct',
      'price': '\$45.99',
      'rating': 4.8,
      'delivery': '2-3 days',
      'stock': 'In Stock',
    },
    {
      'name': 'Farm Equipment Store',
      'price': '\$48.50',
      'rating': 4.5,
      'delivery': '3-5 days',
      'stock': 'In Stock',
    },
    {
      'name': 'Tractor Parts Plus',
      'price': '\$52.99',
      'rating': 4.9,
      'delivery': '1-2 days',
      'stock': 'Low Stock',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image Gallery
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.grey.shade700,
                ),
                onPressed: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isFavorite
                          ? 'Added to favorites'
                          : 'Removed from favorites'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // Share functionality
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      itemCount: 3,
                      onPageChanged: (index) {
                        setState(() {
                          _selectedImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Container(
                          color: Colors.white,
                          child: widget.uploadedImage != null
                              ? Image.file(
                                  widget.uploadedImage!,
                                  fit: BoxFit.contain,
                                )
                              : Center(
                                  child: Icon(
                                    Icons.settings,
                                    size: 100,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                  // Image indicators
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedImageIndex == index
                                ? Colors.green.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Part Info Section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Rating
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.sparePart['name'] ?? 'Engine Oil Filter',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                index < 4 ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '4.7 (${_reviews.length} reviews)',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Part Number
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Part #: ${widget.sparePart['partNumber'] ?? 'EF-2024-A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Price Section
                      Row(
                        children: [
                          Text(
                            widget.sparePart['price'] ?? '\$45.99',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.sparePart['availability'] ?? 'In Stock',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Quantity Selector
                      Row(
                        children: [
                          const Text(
                            'Quantity:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    if (_quantity > 1) {
                                      setState(() {
                                        _quantity--;
                                      });
                                    }
                                  },
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    _quantity.toString(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      _quantity++;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Tabs Section
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.green.shade700,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: Colors.green.shade700,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Specs'),
                      Tab(text: 'Reviews'),
                      Tab(text: 'Suppliers'),
                    ],
                  ),
                ),
                Container(
                  height: 400,
                  color: Colors.white,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildSpecsTab(),
                      _buildReviewsTab(),
                      _buildSuppliersTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'High-quality engine oil filter designed for optimal performance. Features advanced filtration technology to protect your engine from contaminants and ensure long-lasting operation.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Key Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem('Superior filtration efficiency'),
          _buildFeatureItem('Extended service life'),
          _buildFeatureItem('Easy installation'),
          _buildFeatureItem('OEM quality standards'),
          _buildFeatureItem('Compatible with synthetic oils'),
          const SizedBox(height: 20),
          const Text(
            'Compatibility',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...((widget.sparePart['compatibility'] as List?) ?? []).map(
            (model) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    model,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
          const SizedBox(width: 8),
          Text(
            feature,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpecRow('Diameter', '3.5 inches'),
          _buildSpecRow('Height', '4.2 inches'),
          _buildSpecRow('Thread Size', '3/4-16 UNF'),
          _buildSpecRow('Filter Media', 'Synthetic blend'),
          _buildSpecRow('Micron Rating', '25'),
          _buildSpecRow('Maximum Pressure', '150 PSI'),
          _buildSpecRow('Operating Temp', '-40°F to 300°F'),
          _buildSpecRow('Warranty', '12 months'),
          _buildSpecRow('Weight', '0.8 lbs'),
          _buildSpecRow('Made In', 'USA'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          review['user'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (review['verified'])
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      review['date'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review['rating'] ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  review['comment'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuppliersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _suppliers.length,
      itemBuilder: (context, index) {
        final supplier = _suppliers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      supplier['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          supplier['rating'].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          supplier['price'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Delivery',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          supplier['delivery'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Buy from this supplier'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Add to Cart'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                  side: BorderSide(color: Colors.green.shade700, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Buy Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}