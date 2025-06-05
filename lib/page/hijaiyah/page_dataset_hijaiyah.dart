import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ML_Gweh/config/loading_page.dart';
import 'package:flutter/services.dart';

class SpecificDatasetPage extends StatefulWidget {
  final String datasetType;
  // Static cache to store fetched URLs
  static final Map<String, List<String>> _cache = {};

  const SpecificDatasetPage({super.key, required this.datasetType});

  @override
  State<SpecificDatasetPage> createState() => _SpecificDatasetPageState();
}

class _SpecificDatasetPageState extends State<SpecificDatasetPage> {
  List<String> imageUrls = [];
  bool _isLoading = true;
  String _error = '';
  bool _isRefreshing = false; // Add this variable
  // Add these variables
  Set<int> selectedIndices = {};
  bool isSelectionMode = false;
  // Tambahkan variabel untuk progres
  double _progress = 0.0;
  final bool _isLoadingInBackground = false;

  // Add method to check loading status
  bool get isLoading => _isLoading || _isLoadingInBackground;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    // Check if data exists in cache
    if (SpecificDatasetPage._cache.containsKey(widget.datasetType)) {
      setState(() {
        imageUrls = SpecificDatasetPage._cache[widget.datasetType]!;
        _isLoading = false;
      });
      return;
    }

    // If not in cache, fetch from Firebase
    await _fetchImages();
  }

  Future<void> _fetchImages() async {
    try {
      final storageRef =
          FirebaseStorage.instance.ref().child(widget.datasetType);
      final ListResult result = await storageRef.listAll();
      List<String> urls = [];

      // Reset progres
      if (mounted) {
        setState(() {
          _progress = 0.0;
        });
      }

      for (int i = 0; i < result.items.length; i++) {
        var item = result.items[i];
        String url = await item.getDownloadURL();
        urls.add(url);

        // Perbarui progres hanya jika widget masih mounted
        if (mounted) {
          setState(() {
            _progress = (i + 1) / result.items.length;
          });
        }
      }

      // Simpan ke cache
      SpecificDatasetPage._cache[widget.datasetType] = urls;

      // Update state hanya jika widget masih mounted
      if (mounted) {
        setState(() {
          imageUrls = urls;
          _isLoading = false;
          _progress = 0.0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _progress = 0.0;
        });
      }
      print('Error fetching images: $e');
    }
  }

  Future<void> _fetchNewImages() async {
    setState(() => _isRefreshing = true); // Start loading
    try {
      final storageRef =
          FirebaseStorage.instance.ref().child(widget.datasetType);
      final ListResult result = await storageRef.listAll();

      // Get list of existing image names to avoid duplicates
      Set<String> existingUrls = imageUrls.toSet();
      List<String> newUrls = [];

      // Show loading indicator only for new data
      setState(() {
        _error = '';
      });

      // Check each item and only fetch new ones
      for (var item in result.items) {
        String url = await item.getDownloadURL();
        if (!existingUrls.contains(url)) {
          newUrls.add(url);
        }
      }

      // Update state only if new images were found
      if (newUrls.isNotEmpty) {
        setState(() {
          imageUrls.addAll(newUrls);
          // Update cache with new combined data
          SpecificDatasetPage._cache[widget.datasetType] = imageUrls;
          _isRefreshing = false; // Stop loading
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newUrls.length} new images added'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        setState(() => _isRefreshing = false); // Stop loading
        // Show no new data message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No new images found'),
            backgroundColor: Colors.blue.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isRefreshing = false; // Stop loading on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      print('Error fetching new images: $e');
    }
  }

  // Add this method to handle deletion
  Future<void> _deleteSelectedImages() async {
    try {
      setState(() => _isLoading = true);

      // Get Firebase storage reference
      final storage = FirebaseStorage.instance;

      // Delete each selected image
      for (int index in selectedIndices) {
        final imageUrl = imageUrls[index];
        // Get reference from URL and delete
        try {
          final ref = storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          print('Error deleting image at index $index: $e');
        }
      }

      // Update local state and cache
      // Update the setState block in _deleteSelectedImages method
      setState(() {
        // Fix the removeWhere by using the correct index handling
        imageUrls.removeWhere(
            (url) => selectedIndices.contains(imageUrls.indexOf(url)));
        SpecificDatasetPage._cache[widget.datasetType] = imageUrls;
        selectedIndices.clear();
        isSelectionMode = false;
        _isLoading = false;
      });

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selectedIndices.length} images deleted'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting images: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Loading process will continue in background'),
              backgroundColor: Colors.blue.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          // Kembalikan true untuk mengizinkan navigasi kembali
          return true;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.blue.shade50
            .withOpacity(0.8), // Set a consistent background color
        appBar: _isLoading
            ? null
            : AppBar(
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                ),
                backgroundColor: Colors.blue.shade50
                    .withOpacity(0.8), // Match Scaffold background
                elevation: 0,
                centerTitle: false,
                toolbarHeight: 70,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                leading: isSelectionMode
                    ? IconButton(
                        icon: Icon(Icons.close, color: Colors.blue.shade700),
                        onPressed: () {
                          setState(() {
                            selectedIndices.clear();
                            isSelectionMode = false;
                          });
                        },
                      )
                    : IconButton(
                        icon: Icon(Icons.arrow_back_ios_new,
                            color: Colors.blue.shade700),
                        onPressed: () => Navigator.pop(context),
                      ),
                title: isSelectionMode
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.blue.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade100.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 20, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              '${selectedIndices.length} Selected',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dataset ${widget.datasetType.split('/').last}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.photo_library_outlined,
                                    size: 14, color: Colors.blue.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  '${imageUrls.length} Images',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                actions: [
                  if (isSelectionMode) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: selectedIndices.isEmpty
                                ? Colors.grey
                                : Colors.red.shade400),
                        onPressed:
                            selectedIndices.isEmpty ? null : _showDeleteDialog,
                      ),
                    ),
                  ] else ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: _isRefreshing
                            ? Colors.grey.shade100
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        icon: _isRefreshing
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue.shade400),
                                ),
                              )
                            : Icon(Icons.refresh_rounded,
                                color: Colors.blue.shade700),
                        onPressed: _isRefreshing ? null : _fetchNewImages,
                      ),
                    ),
                  ],
                ],
              ),
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return LoadingPage(progress: _progress);
    }

    if (_error.isNotEmpty) {
      return _buildErrorState();
    }

    if (imageUrls.isEmpty) {
      return _buildEmptyState();
    }

    return _buildGridView();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading dataset',
            style: TextStyle(
              color: Colors.red.shade300,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        final isSelected = selectedIndices.contains(index);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: isSelected
                ? Border.all(color: Colors.blue.shade400, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? Colors.blue.shade100.withOpacity(0.5)
                    : Colors.black.withOpacity(0.1),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _handleImageTap(index),
                    onLongPress: () => _handleImageLongPress(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade400,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleImageTap(int index) {
    if (isSelectionMode) {
      setState(() {
        if (selectedIndices.contains(index)) {
          selectedIndices.remove(index);
          if (selectedIndices.isEmpty) {
            isSelectionMode = false;
          }
        } else {
          selectedIndices.add(index);
        }
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  'Image ${index + 1}',
                  style: const TextStyle(
                    color: Colors.black87,
                  ),
                ),
              ),
              InteractiveViewer(
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _handleImageLongPress(int index) {
    if (!isSelectionMode) {
      setState(() {
        isSelectionMode = true;
        selectedIndices.add(index);
      });
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text('Delete Images'),
        content: Text('Delete ${selectedIndices.length} selected images?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedImages();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
