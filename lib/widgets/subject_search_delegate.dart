import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/units_screen.dart';

class SubjectItem {
  final String id;
  final String name;
  final String branchId;

  SubjectItem({required this.id, required this.name, required this.branchId});

  factory SubjectItem.fromMap(Map<String, dynamic> map) {
    return SubjectItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      branchId: map['branchId'] ?? '',
    );
  }
}

class _MatchScore {
  final SubjectItem subject;
  final int score;

  _MatchScore(this.subject, this.score);
}

class SubjectSearchDelegate extends SearchDelegate<String?> {
  static List<SubjectItem>? _globalSubjectCache;
  static bool _isLoading = false;

  // RUN THIS ONCE to generate the initial index in Firestore
  static Future<void> buildSearchIndex() async {
    debugPrint("Building search index...");
    List<Map<String, dynamic>> allSubjects = [];
    final branchesSnapshot = await FirebaseFirestore.instance.collection('branches').get();
    
    for (var branchDoc in branchesSnapshot.docs) {
      try {
        final subjectsSnapshot = await branchDoc.reference.collection('subjects').get();
        for (var subjectDoc in subjectsSnapshot.docs) {
          allSubjects.add({
            'id': subjectDoc.id,
            'name': subjectDoc.data()['name'] ?? 'Unknown Subject',
            'branchId': branchDoc.id,
          });
        }
      } catch (e) {
        continue;
      }
    }
    
    await FirebaseFirestore.instance.collection('search_index').doc('global').set({
      'subjects': allSubjects,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    debugPrint("Search index built successfully with ${allSubjects.length} subjects!");
  }

  Future<List<SubjectItem>> _getSubjects() async {
    if (_globalSubjectCache != null) return _globalSubjectCache!;
    if (_isLoading) {
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _globalSubjectCache ?? [];
    }

    _isLoading = true;
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('search_index')
          .doc('global')
          .get(const GetOptions(source: Source.serverAndCache));
      
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final List<dynamic> subjectsList = docSnapshot.data()!['subjects'] ?? [];
        _globalSubjectCache = subjectsList
            .map((e) => SubjectItem.fromMap(e as Map<String, dynamic>))
            .toList();
      } else {
        _globalSubjectCache = [];
      }
    } catch (e) {
      debugPrint("Error fetching search index: $e");
      _globalSubjectCache = [];
    } finally {
      _isLoading = false;
    }
    return _globalSubjectCache!;
  }

  int _levenshteinDistance(String s, String t) {
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i <= t.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost
        ].reduce((a, b) => a < b ? a : b);
      }

      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
  }

  @override
  String get searchFieldLabel => 'Search subjects...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildHighlightedTitle(BuildContext context, String title, String query, bool isDark) {
    if (query.isEmpty) {
      return Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black));
    }

    final lowerTitle = title.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final matchIndex = lowerTitle.indexOf(lowerQuery);
    if (matchIndex == -1) {
      return Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black));
    }

    return Text.rich(
      TextSpan(
        text: title.substring(0, matchIndex),
        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.black54, fontWeight: FontWeight.normal),
        children: [
          TextSpan(
            text: title.substring(matchIndex, matchIndex + query.length),
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: title.substring(matchIndex + query.length),
            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.black54, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      style: const TextStyle(fontSize: 16),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (query.trim().isEmpty) {
      return Center(
        child: Text(
          'Type to search for subjects...',
          style: TextStyle(fontSize: 16, color: isDark ? Colors.grey[400] : Colors.grey),
        ),
      );
    }

    return FutureBuilder<List<SubjectItem>>(
      future: _getSubjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 64, color: isDark ? Colors.grey[500] : Colors.grey[600]),
                  const SizedBox(height: 16),
                  const Text(
                    "Network Error",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Error: ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildNoResults(isDark);
        }

        final lowerQuery = query.toLowerCase().trim();
        final queryWords = lowerQuery.split(RegExp(r'\s+'));
        final allDocs = snapshot.data!;
        
        // Generate short form of the query (e.g. "software engineering" -> "se")
        String queryShortForm = '';
        for (var word in queryWords) {
          if (word.isNotEmpty) queryShortForm += word[0];
        }
        
        final filteredScoredDocs = <_MatchScore>[];
        
        // Client-side filtering
        for (var subject in allDocs) {
          final name = subject.name.toLowerCase();
          
          // 1. Exact match
          if (name == lowerQuery) {
            filteredScoredDocs.add(_MatchScore(subject, 100));
            continue;
          }
          
          // 2. Starts with query
          if (name.startsWith(lowerQuery)) {
            filteredScoredDocs.add(_MatchScore(subject, 80));
            continue;
          }

          // 3. Exact or partial substring match
          if (name.contains(lowerQuery)) {
            filteredScoredDocs.add(_MatchScore(subject, 60));
            continue;
          }
          
          // 4. All query words present in the subject name
          bool allWordsPresent = true;
          for (var qWord in queryWords) {
            if (qWord.isEmpty) continue;
            if (!name.contains(qWord)) {
              allWordsPresent = false;
              break;
            }
          }
          if (allWordsPresent && queryWords.length > 1) {
            filteredScoredDocs.add(_MatchScore(subject, 50));
            continue;
          }
          
          // 5. Short form of the subject matching the query
          // (DB has "Software Engineering", User typed "se")
          final subjectWords = name.split(RegExp(r'\s+'));
          String subjectShortForm = '';
          for (var word in subjectWords) {
            if (word.isNotEmpty) subjectShortForm += word[0];
          }
          if (subjectShortForm.contains(lowerQuery) && lowerQuery.length > 1) {
            filteredScoredDocs.add(_MatchScore(subject, 40));
            continue;
          }

          // 6. Short form of the query matching the subject
          // (DB has "se", User typed "Software Engineering")
          if (name == queryShortForm && queryShortForm.length > 1) {
            filteredScoredDocs.add(_MatchScore(subject, 30));
            continue;
          }

          // 7. Fuzzy Matching to handle spelling mistakes
          bool fuzzyMatched = false;
          for (var qWord in queryWords) {
            if (qWord.length <= 3) continue; // Skip tiny words
            for (var sWord in subjectWords) {
              if (sWord.length <= 3) continue;
              
              int distance = _levenshteinDistance(qWord, sWord);
              // Tolerate 1 mistake for words > 3 chars, and 2 mistakes for words > 5 chars
              if (distance <= 1 || (qWord.length > 5 && distance <= 2)) {
                filteredScoredDocs.add(_MatchScore(subject, 20 - distance));
                fuzzyMatched = true;
                break;
              }
            }
            if (fuzzyMatched) break;
          }
        }

        if (filteredScoredDocs.isEmpty) {
          return _buildNoResults(isDark);
        }

        // Sort by score (descending)
        filteredScoredDocs.sort((a, b) => b.score.compareTo(a.score));

        return ListView.builder(
          itemCount: filteredScoredDocs.length,
          itemBuilder: (context, index) {
            final subject = filteredScoredDocs[index].subject;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isDark ? Colors.grey[800] : const Color(0xFFE8E8E8),
                child: Icon(Icons.menu_book, color: isDark ? Colors.grey[400] : Colors.black54),
              ),
              title: _buildHighlightedTitle(context, subject.name, query.trim(), isDark),
              subtitle: Text('Branch: ${subject.branchId}', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[700])),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UnitsScreen(
                      branchId: subject.branchId,
                      subjectId: subject.id,
                      subjectName: subject.name,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNoResults(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              "Subject Not Found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Please check your spelling.\nYou can also try searching by its short form (e.g., 'SE' for Software Engineering).",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
