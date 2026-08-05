import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:waterman_iattandance/screens/my_portfolio_screen/view_model/my_portfolio_controller.dart';
import 'package:waterman_iattandance/screens/new_customer_dealer_screen/view/new_customer_dealer_screen.dart';

import '../model/my_portfolio_response_model.dart';
import '../../../flavor_config.dart';

class MyPortfolioScreen extends StatefulWidget {
  const MyPortfolioScreen({super.key});

  @override
  State<MyPortfolioScreen> createState() => _MyPortfolioScreenState();
}

class _MyPortfolioScreenState extends State<MyPortfolioScreen> {
  final MyPortfolioController controller = Get.put(MyPortfolioController());

  @override
  void initState() {
    super.initState();
    controller.fetchPortfolio();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        leading: FlavorConfig.instance.getAppBarLeading(context),
        backgroundColor: FlavorConfig.instance.appBarColor,
        bottom: FlavorConfig.instance.getAppBarBottom(),
        title: Text("My Portfolio", style: TextStyle(color: FlavorConfig.instance.appBarForegroundColor)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// 🔍 SEARCH
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                  )
                ],
              ),
              child: TextField(
                onChanged: controller.filterSearch,
                decoration: const InputDecoration(
                  hintText: "Search company, city, person...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// 📋 LIST
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(child: CircularProgressIndicator(color: FlavorConfig.instance.primaryColor));
                }

                if (controller.filteredList.isEmpty) {
                  return const Center(child: Text("No portfolio found"));
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: controller.filteredList.length,
                  itemBuilder: (context, index) {
                    final item = controller.filteredList[index];

                    return PortfolioCard(
                      company: item.companyName ?? '',
                      city: item.city ?? '',
                      person: item.contactPersonName ?? '',
                      phone: item.contactPersonMobileNo ?? '',
                      portfolioId: item.portfolioId ?? '',
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}


class PortfolioCard extends StatelessWidget {
  final String company;
  final String city;
  final String person;
  final String phone;
  final String portfolioId;

  const PortfolioCard({
    super.key,
    required this.company,
    required this.city,
    required this.person,
    required this.phone, required this.portfolioId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          /// 📍 Location Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [FlavorConfig.instance.primaryLightColor, FlavorConfig.instance.primaryColor],
              ),
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 30),
          ),

          const SizedBox(width: 12),

          /// 📄 Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$company, $city",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  person,
                  style: TextStyle(color: Colors.grey.shade600),
                ),

                const SizedBox(height: 8),

                /// 📞 Call Button
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: FlavorConfig.instance.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.call, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        phone,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// ✏️ Edit
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.orange),
            onPressed: () async {
              await Get.to(NewCustomerDealerScreen(portfolioId: portfolioId));
              Get.find<MyPortfolioController>().fetchPortfolio();
            },
          )
        ],
      ),
    );
  }
}
