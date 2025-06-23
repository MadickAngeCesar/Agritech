import 'package:flutter/material.dart';

class FAQSection extends StatelessWidget {
  const FAQSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 20),
            _buildResponsiveGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 2 : 1;
    final childAspectRatio = screenWidth > 600 ? 1.8 : 2.2;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: childAspectRatio,
      children: _getFAQItems().map((faq) => _buildFAQCard(faq)).toList(),
    );
  }

  Widget _buildFAQCard(FAQItem faq) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              faq.question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                faq.answer,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FAQItem> _getFAQItems() {
    return [
      FAQItem(
        question: "How do I track crop prices?",
        answer: "Go to the Market Updates section on the home screen to view current crop prices and market trends.",
      ),
      FAQItem(
        question: "How can I access weather updates?",
        answer: "Navigate to the Weather section on the homepage for detailed weather forecasts and alerts.",
      ),
      FAQItem(
        question: "How do I report crop diseases?",
        answer: "Use the Crop Disease Detection feature in the app to capture images and get instant disease identification.",
      ),
      FAQItem(
        question: "How do I manage my farm inventory?",
        answer: "Check the Inventory Management section in the app to track your seeds, fertilizers, and equipment.",
      ),
      FAQItem(
        question: "Can I connect with agricultural experts?",
        answer: "Yes, you can use the Expert Consultation platform to connect with agricultural specialists and get advice.",
      ),
      FAQItem(
        question: "How do I access farming tips?",
        answer: "Go to the Education section for videos, articles, and best practices for modern farming techniques.",
      ),
      FAQItem(
        question: "How can I get crop insurance information?",
        answer: "Navigate to the Insurance section to explore different crop insurance options and application processes.",
      ),
      FAQItem(
        question: "How do I get technical support?",
        answer: "You can reach out via chat, email, or phone support available in the app's help section.",
      ),
      FAQItem(
        question: "How do I reset my password?",
        answer: "Go to the account settings and click on 'Reset Password' to receive reset instructions via email.",
      ),
      FAQItem(
        question: "How do I change my language preference?",
        answer: "Go to settings and choose your preferred language from the available options.",
      ),
      FAQItem(
        question: "How can I add a new crop to my farm profile?",
        answer: "Navigate to Farm Profile, then click 'Add New Crop' to include additional crops in your farming portfolio.",
      ),
      FAQItem(
        question: "What should I do if I encounter an app bug?",
        answer: "Report it through the 'Submit a Request' option in the help section with detailed information about the issue.",
      ),
    ];
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}

