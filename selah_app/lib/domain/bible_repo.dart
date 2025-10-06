abstract class BibleRepo {
  Future<void> prefetch(List<String> passageRefs);
  Future<String> fetchPassage(String passageRef);
  Future<void> downloadVersion(String version);
  Future<List<dynamic>> versions();
}