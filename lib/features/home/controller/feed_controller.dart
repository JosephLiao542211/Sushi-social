import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/social_post.dart';

class FeedController {
  final _supabase = Supabase.instance.client;

  Future<List<SocialPost>> fetchFeed() async {
    final rows = await _supabase
        .from('feed_posts')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    final posts = rows.map(SocialPost.fromMap).toList();
    return _withSignedPhotoUrls(posts);
  }

  Future<void> createPost({
    required XFile photo,
    required String caption,
    required int plateCount,
    String? locationName,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const AuthException('You are not signed in.');
    final upload = await uploadPhoto(photo);
    final photoUrl = upload.publicUrl;

    String? locationId;
    final locName = locationName?.trim() ?? '';
    if (locName.isNotEmpty) {
      final existing = await _supabase
          .from('locations')
          .select('id')
          .ilike('name', locName)
          .maybeSingle();
      if (existing != null) {
        locationId = existing['id'] as String;
      } else {
        final inserted = await _supabase
            .from('locations')
            .insert({'name': locName})
            .select('id')
            .single();
        locationId = inserted['id'] as String;
      }
    }

    await _supabase.from('posts').insert({
      'author_id': userId,
      'location_id': locationId,
      'photo_url': photoUrl.trim(),
      'caption': caption.trim(),
      'plate_count': plateCount,
      'photo_storage': 'google_cloud_storage',
      'photo_bucket': upload.bucket,
      'photo_object_path': upload.objectPath,
    });
  }

  Future<UploadedPhoto> uploadPhoto(XFile photo) async {
    final contentType = photo.mimeType ?? _contentTypeFor(photo.name);
    final upload = await createPhotoUpload(contentType: contentType);
    final bytes = await photo.readAsBytes();

    final response = await http.put(
      Uri.parse(upload['uploadUrl'] as String),
      headers: {'Content-Type': contentType},
      body: bytes,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Photo upload failed with ${response.statusCode}: ${response.body}',
      );
    }

    return UploadedPhoto(
      publicUrl: upload['publicUrl'] as String,
      bucket: upload['bucket'] as String,
      objectPath: upload['objectPath'] as String,
    );
  }

  Future<void> toggleLike(SocialPost post) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const AuthException('You are not signed in.');

    if (post.likedByMe) {
      await _supabase
          .from('post_likes')
          .delete()
          .eq('post_id', post.id)
          .eq('user_id', userId);
      return;
    }

    await _supabase.from('post_likes').insert({
      'post_id': post.id,
      'user_id': userId,
    });
  }

  Future<void> addComment({
    required String postId,
    required String body,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const AuthException('You are not signed in.');

    await _supabase.from('post_comments').insert({
      'post_id': postId,
      'author_id': userId,
      'body': body.trim(),
    });
  }

  Future<Map<String, dynamic>> createPhotoUpload({
    required String contentType,
  }) async {
    final result = await _supabase.functions.invoke(
      'create-photo-upload',
      body: {'contentType': contentType},
    );
    return result.data as Map<String, dynamic>;
  }

  Future<List<SocialPost>> _withSignedPhotoUrls(List<SocialPost> posts) async {
    final objectPaths = posts
        .map((post) => post.photoObjectPath)
        .whereType<String>()
        .toSet()
        .toList();
    if (objectPaths.isEmpty) return posts;

    final result = await _supabase.functions.invoke(
      'sign-photo-urls',
      body: {'objectPaths': objectPaths},
    );
    final urls = Map<String, dynamic>.from(result.data['urls'] as Map);

    return posts.map((post) {
      final objectPath = post.photoObjectPath;
      final signedUrl = objectPath == null ? null : urls[objectPath] as String?;
      return signedUrl == null ? post : post.copyWith(imageUrl: signedUrl);
    }).toList();
  }

  String _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}

class UploadedPhoto {
  final String publicUrl;
  final String bucket;
  final String objectPath;

  const UploadedPhoto({
    required this.publicUrl,
    required this.bucket,
    required this.objectPath,
  });
}
