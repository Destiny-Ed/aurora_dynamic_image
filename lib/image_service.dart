import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator_master/palette_generator_master.dart';
import 'package:http/http.dart' as http;

/// Represents the result of fetching the random image from the API.
class ImageFetchResult {
  final String? imageUrl;
  final String status;

  bool get isSuccess => (imageUrl ?? "").isNotEmpty;
  bool get hasError => !isSuccess;

  const ImageFetchResult.success(this.imageUrl) : status = 'Success';
  const ImageFetchResult.error(this.status) : imageUrl = null;

  @override
  String toString() => 'ImageFetchResult(imageUrl: $imageUrl, status: $status)';
}

Future<ImageFetchResult> fetchImage() async {
  try {
    final uri = Uri.parse(
      'https://november7-730026606190.europe-west1.run.app/image',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      return ImageFetchResult.error('Server error: ${response.statusCode}');
    }

    final jsonBody = json.decode(response.body);

    final url = jsonBody['url'];
    if (url is String && url.trim().isNotEmpty) {
      return ImageFetchResult.success(url.trim());
    }

    return const ImageFetchResult.error('Empty or invalid image URL received');
  } on SocketException {
    return const ImageFetchResult.error('No internet connection');
  } on TimeoutException {
    return const ImageFetchResult.error('Request timed out');
  } on FormatException {
    return const ImageFetchResult.error('Invalid response format');
  } catch (e) {
    return ImageFetchResult.error('Unexpected error: $e');
  }
}

Future<Color?> updateBackground(String imageUrl) async {
  try {
    final paletteGenerator = await PaletteGeneratorMaster.fromImageProvider(
      CachedNetworkImageProvider(imageUrl),
    );

    return paletteGenerator.dominantColor?.color;
  } catch (e) {
    return null;
  }
}
