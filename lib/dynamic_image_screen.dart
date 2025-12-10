import 'dart:developer';

import 'package:aurora_dynamic_image/image_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DynamicImageScreen extends StatefulWidget {
  const DynamicImageScreen({super.key});

  @override
  State<DynamicImageScreen> createState() => _DynamicImageScreenState();
}

class _DynamicImageScreenState extends State<DynamicImageScreen>
    with SingleTickerProviderStateMixin {
  String? _imageUrl;
  Color _backgroundColor = Colors.transparent;
  bool _isLoading = false;
  bool _hasError = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fetchImageAndApplyBgColor();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _fetchImageAndApplyBgColor() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final result = await fetchImage();
    log("image result: ${result.toString()}");

    if (result.isSuccess) {
      setState(() {
        _imageUrl = result.imageUrl;
        _isLoading = false;
      });
      final color = await updateBackground(result.imageUrl!);
      log("dominant bg color result : $color");
      setState(() {
        _backgroundColor = color ?? Theme.of(context).scaffoldBackgroundColor;
      });

      //fade image in
      _fadeController.forward(from: 0.0);
      _annouce('New image loaded');
    } else {
      _handleError(result.status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Image section
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (_hasError || _imageUrl == null)
                    ? Center(
                        child: Column(
                          spacing: 20,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.white70,
                            ),
                            Text(
                              'Failed to load image',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                            Semantics(
                              label: "Retry Image Button",
                              child: ElevatedButton(
                                onPressed: _fetchImageAndApplyBgColor,
                                child: const Text('Retry'),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: Semantics(
                          label: 'Random image',
                          excludeSemantics: true,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: InteractiveViewer(
                              trackpadScrollCausesScale: true,
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: CachedNetworkImage(
                                    imageUrl: _imageUrl ?? "",
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(
                                          Icons.image_not_supported,
                                          size: 64,
                                          color: Colors.white70,
                                        ),
                                    fadeInDuration: const Duration(
                                      milliseconds: 300,
                                    ),
                                    fadeOutDuration: const Duration(
                                      milliseconds: 300,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),

              // Button
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  label: "Generate Image Button",
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _fetchImageAndApplyBgColor,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(_isLoading ? 'Loading...' : 'Another'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleError(String message) {
    setState(() {
      _isLoading = false;
      _hasError = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _fetchImageAndApplyBgColor,
          ),
        ),
      );
      _annouce(message);
    }
  }

  void _annouce(String message) {
    SemanticsService.announce(message, Directionality.of(context));
  }
}
