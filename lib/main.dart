import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: ImageGalleryScreen(changeTheme: changeTheme),
    );
  }
}

class ImageGalleryScreen extends StatefulWidget {
  final Function(ThemeMode) changeTheme;

  const ImageGalleryScreen({super.key, required this.changeTheme});

  @override
  _ImageGalleryScreenState createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  List<Map<String, dynamic>> images = [];
  List<Map<String, dynamic>> filteredImages = [];
  bool isLoading = true;
  String searchText = '';
  double ratingFilter = 0.0;

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages({String query = ''}) async {
  const accessKey = 'Jnv03a_Z5loWn58V1I2ICr24g7N7dIN_M7Zi3xKCNlI';  //  Unsplash API Access Key here
  final url = query.isEmpty
      ? 'https://api.unsplash.com/photos?per_page=30&client_id=$accessKey'
      : 'https://api.unsplash.com/search/photos?query=$query&per_page=30&client_id=$accessKey';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = query.isEmpty
          ? json.decode(response.body)
          : json.decode(response.body)['results'];

      setState(() {
        images = data
            .map((e) => {
                  'url': e['urls']['small'],
                  'title': e['alt_description'] ?? 'Untitled',
                  'rating': 0.0,
                })
            .toList();
        filteredImages = images;
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load images');
    }
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    rethrow;
  }
}


  void filterImages() {
    setState(() {
      filteredImages = images
          .where((image) =>
              image['rating'] >= ratingFilter &&
              (searchText.isEmpty ||
                  image['title'].toLowerCase().contains(searchText.toLowerCase())))
          .toList();
    });
  }

  @override
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Image Gallery'),
      actions: [
        IconButton(
          icon: const Icon(Icons.brightness_6),
          onPressed: () {
            final theme = Theme.of(context).brightness == Brightness.light
                ? ThemeMode.dark
                : ThemeMode.light;
            widget.changeTheme(theme);
          },
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                searchText = value;
              });
              filterImages();
            },
          ),
        ),
        Slider(
          value: ratingFilter,
          min: 0,
          max: 5,
          divisions: 5,
          label: 'Filter by Rating: ${ratingFilter.toStringAsFixed(1)}',
          onChanged: (value) {
            setState(() {
              ratingFilter = value;
            });
            filterImages();
          },
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filteredImages.length,
                  itemBuilder: (context, index) {
                    final image = filteredImages[index];
                    return Tooltip(
                      message: image['description'] ?? 'No description available',
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImageGallery(
                                images: filteredImages,
                                initialIndex: index,
                                onRatingUpdate: (rating) {
                                  setState(() {
                                    images[images.indexOf(image)]['rating'] = rating;
                                    filterImages();
                                  });
                                },
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Image.network(
                              image['url'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            Container(
                              color: Colors.black.withOpacity(0.5),
                              padding: const EdgeInsets.all(5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 5),
                                  Text(
                                    image['rating'].toStringAsFixed(1),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
}



class FullScreenImageGallery extends StatefulWidget {
  final List<Map<String, dynamic>> images;
  final int initialIndex;
  final Function(double) onRatingUpdate;

  const FullScreenImageGallery({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.onRatingUpdate,
  });

  @override
  _FullScreenImageGalleryState createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<FullScreenImageGallery> {
  late PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Screen Image'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(widget.images[index]['url']),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              scrollPhysics: const BouncingScrollPhysics(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Text(
                  widget.images[currentIndex]['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text('Rate this Image'),
                RatingBar.builder(
                  initialRating: widget.images[currentIndex]['rating'],
                  minRating: 0,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      widget.images[currentIndex]['rating'] = rating;
                    });
                    widget.onRatingUpdate(rating);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

