import 'package:khmer_cat_app/core/network/api_client.dart';
import 'package:khmer_cat_app/core/network/api_response.dart';
import 'package:khmer_cat_app/core/network/api_route.dart';

class CommentsRemoteDataSource {
  final ApiClient _client;
  CommentsRemoteDataSource(this._client);

  Future<Map<String, dynamic>> getComments(
    String videoId, {
    int page = 1,
  }) async {
    final json = await _client.get(
      ApiRoute.videoComments(videoId),
      query: {'page': page},
    );
    return json.dataMap;
  }

  Future<Map<String, dynamic>> postComment(String videoId, String body) async {
    final json = await _client.post(
      ApiRoute.videoComments(videoId),
      body: {'body': body},
    );
    return json.dataMap;
  }

  Future<void> deleteComment(String commentId) async {
    await _client.delete(ApiRoute.comment(commentId));
  }

  Future<Map<String, dynamic>> toggleLike(String commentId) async {
    final json = await _client.post(ApiRoute.commentLike(commentId));
    return json.dataMap;
  }
}
