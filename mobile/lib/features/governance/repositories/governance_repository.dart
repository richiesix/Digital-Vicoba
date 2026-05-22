import '../../../core/network/api_client.dart';

class GovernanceRepository {
  GovernanceRepository(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> fetchDashboard(int groupId) async {
    final res = await _api.get('/groups/$groupId/governance');
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchElections(int groupId, {String? status}) async {
    final res = await _api.get(
      '/groups/$groupId/elections',
      queryParameters: status != null ? {'status': status} : null,
    );
    return (res.data['elections'] as List?) ?? [];
  }

  Future<Map<String, dynamic>> fetchElection(int electionId) async {
    final res = await _api.get('/elections/$electionId');
    return res.data['election'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createElection(int groupId, Map<String, dynamic> body) async {
    final res = await _api.post('/groups/$groupId/elections', data: body);
    return res.data['election'] as Map<String, dynamic>;
  }

  Future<void> openElection(int electionId) async {
    await _api.post('/elections/$electionId/open');
  }

  Future<void> nominate(int electionId, Map<String, dynamic> body) async {
    await _api.post('/elections/$electionId/nominate', data: body);
  }

  Future<void> castVote(int electionId, Map<String, dynamic> body) async {
    await _api.post('/elections/$electionId/vote', data: body);
  }

  Future<bool> hasVoted(int electionId, int memberId) async {
    final res = await _api.get(
      '/elections/$electionId/vote-status',
      queryParameters: {'member_id': memberId},
    );
    return res.data['has_voted'] as bool? ?? false;
  }

  Future<Map<String, dynamic>> fetchResults(int electionId) async {
    final res = await _api.get('/elections/$electionId/results');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> closeElection(int electionId) async {
    final res = await _api.post('/elections/$electionId/close');
    return res.data as Map<String, dynamic>;
  }

  Future<void> syncVotes(int electionId, List<Map<String, dynamic>> votes) async {
    await _api.post('/elections/$electionId/sync-votes', data: {'votes': votes});
  }

  Future<void> proposeAssignment(int groupId, Map<String, dynamic> body) async {
    await _api.post('/groups/$groupId/leadership/assign', data: body);
  }
}
