import 'package:flutter/material.dart';
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
      title: 'Image Gallery with Ratings',
      theme: ThemeData(primarySwatch: Colors.blue),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: ImageGalleryScreen(onThemeChanged: changeTheme),
    );
  }
}

class ImageGalleryScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const ImageGalleryScreen({super.key, required this.onThemeChanged});

  @override
  _ImageGalleryScreenState createState() => _ImageGalleryScreenState();       
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  final List<Map<String, dynamic>> images = [
     {'url': 'https://images.unsplash.com/photo-1511765224389-37f0e77cf0eb', 'rating': 0.0},
    {'url': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSDo890dsxpB5UCLQFdVBWmK4qVxTrsrLEEUg&s', 'rating': 0.0},
    {'url': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRNgRezLFB9BzDht2sgUpL9p-pwBi8W0m3Mag&s', 'rating': 0.0},
    {'url': 'https://images.unsplash.com/photo-1567306226416-28f0efdc88ce', 'rating': 0.0},
    {'url': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSDo890dsxpB5UCLQFdVBWmK4qVxTrsrLEEUg&s', 'rating': 0.0},
  ];

  double _selectedRating = 0.0;

  @override
  Widget build(BuildContext context) {
    final filteredImages = images
        .where((image) => image['rating'] >= _selectedRating)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Gallery with Ratings'),
        actions: [
          PopupMenuButton<ThemeMode>(
            onSelected: widget.onThemeChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ThemeMode.light,
                child: Text('Light Theme'),
              ),
              const PopupMenuItem(
                value: ThemeMode.dark,
                child: Text('Dark Theme'),
              ),
              const PopupMenuItem(
                value: ThemeMode.system,
                child: Text('System Default'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter by Rating:',
                  style: TextStyle(fontSize: 16),
                ),
                DropdownButton<double>(
                  value: _selectedRating,
                  items: [
                    DropdownMenuItem(value: 0.0, child: Text('All')),
                    DropdownMenuItem(value: 1.0, child: Text('1.0+')),
                    DropdownMenuItem(value: 2.0, child: Text('2.0+')),
                    DropdownMenuItem(value: 3.0, child: Text('3.0+')),
                    DropdownMenuItem(value: 4.0, child: Text('4.0+')),
                    DropdownMenuItem(value: 5.0, child: Text('5.0')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRating = value ?? 0.0;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: filteredImages.length,
              itemBuilder: (context, index) {
                final image = filteredImages[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImageGallery(
                          images: images,
                          initialIndex: index,
                          onRatingUpdate: (rating) {
                            setState(() {
                              images[index]['rating'] = rating;
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
                const Text(
                  'Rate this Image',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
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
