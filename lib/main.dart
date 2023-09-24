import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_list_scroll_pagination/models/product_model.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

   
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infinite Scroll Pagination',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Infinite Scroll Pagination'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<Product> productsData =[];

  int totalPages = 300;
  int offSet = 0;
  final RefreshController refreshController = RefreshController(initialRefresh: true);

  Future<bool> getProductsData({bool isRefresh = false}) async {
    if(isRefresh == true) {
      offSet = 0;
    } else {
      if(offSet >= totalPages) {
        refreshController.loadNoData();
        return false;
      }
    }

    final Uri uri = Uri.parse("https://api.escuelajs.co/api/v1/products?offset=$offSet&limit=10");
    final response = await http.get(uri);

    if(response.statusCode == 200) {
      var bodyData = response.body;
      final List<dynamic> parsedList = jsonDecode(bodyData);
      List<Product> newProductsListData = parsedList.map((item) => Product.fromJson(item)).toList();

      if(isRefresh) {
        productsData = newProductsListData;
      } else {
        productsData.addAll(newProductsListData);
      }

      offSet += 10;
      setState(() {});
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
            widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500
          ),
        ),
      ),
      body: SmartRefresher(
        physics: const BouncingScrollPhysics(),
        controller: refreshController,
        enablePullUp: true,
        onRefresh: () async {
          final result = await getProductsData(isRefresh: true);
          if(result) {
            refreshController.refreshCompleted();
          } else {
            refreshController.refreshFailed();
          }
        },
        onLoading: () async {
          final result = await getProductsData();
          if(result) {
            refreshController.loadComplete();
          } else {
            refreshController.loadFailed();
          }
        },
        child: ListView.separated(
          itemCount: productsData.length,
          itemBuilder: (context, index) {
            Product cProduct = productsData[index];
            return Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(
                        Radius.circular(5)
                    ),
                    child: Image(
                      image: NetworkImage(cProduct.images!.first),
                      height: 150,
                      width: MediaQuery.of(context).size.width,
                      fit: BoxFit.cover,
                      errorBuilder: (_,d,s) {
                        return Container(
                            color: Colors.grey.shade300,
                            height: 150,
                            width: MediaQuery.of(context).size.width,
                            child: const Center(
                                child: Text(
                                    "Image Not Found -_-",
                                  style: TextStyle(
                                    color: Colors.grey
                                  ),
                                )
                            ),
                        );
                      },
                    ),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(right: 10, left: 5),
                    title: Text(
                      cProduct.title!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      cProduct.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700
                      ),
                      maxLines: 2, // Limit to two lines
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(
                        cProduct.images!.last
                      ),
                    ),
                    trailing: Text(
                      "\$${cProduct.price.toString() }",
                      style: TextStyle(
                          color: Colors.grey.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (BuildContext context, int index) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Divider(),
          ),
        ),
      ),
    );
  }
}
