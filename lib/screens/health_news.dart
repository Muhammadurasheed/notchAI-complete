import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HealthNews extends StatefulWidget {
  const HealthNews({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _HealthNewsState createState() => _HealthNewsState();
}

class _HealthNewsState extends State<HealthNews> {
  List<dynamic> newsData = [];
  static final healthApikey = dotenv.env['HealthNews_API_KEY'];

  @override
  void initState() {
    super.initState();
    fetchHealthNews();
  }

  Future<void> fetchHealthNews() async {
    var apiUrl =
        'https://newsapi.org/v2/top-headlines?category=health&language=en&apiKey=$healthApikey';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          newsData = jsonData['articles'];
        });
      } else {
        throw Exception('Failed to load health news');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health News'),
        backgroundColor: const Color(0xFF00C6AD),
      ),
      body: ListView.builder(
        itemCount: newsData.length,
        itemBuilder: (context, index) {
          final article = newsData[index];
          final String imageUrl = article['urlToImage'] ?? '';

          return Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullNewsPage(article: article),
                  ),
                );
              },
              child: Column(
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 150,
                          color: Colors.grey,
                        ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article['title'] ?? 'No title available',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          article['description'] ?? 'No description available',
                          style: const TextStyle(fontSize: 14),
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
    );
  }
}

class FullNewsPage extends StatefulWidget {
  final Map<String, dynamic> article;

  const FullNewsPage({Key? key, required this.article}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api, no_logic_in_create_state
  _FullNewsPageState createState() => _FullNewsPageState(article: article);
}

class _FullNewsPageState extends State<FullNewsPage> {
  final Map<String, dynamic> article;

  _FullNewsPageState({required this.article});

  bool isSummarizing = false;

  Future<void> summarizeArticle(BuildContext context) async {
    setState(() {
      isSummarizing = true;
    });

    final openAIKey = dotenv.env['OPENAI_API_KEY'];
    final articleText = article['content'] ?? '';
    const apiUrl = 'https://api.openai.com/v1/engines/text-davinci-003/completions';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $openAIKey',
    };

    final data = {
      'prompt': 'Please summarize the following news article in a clear and concise manner:\n$articleText',
      'max_tokens': 150, // Increase the max_tokens for longer summaries
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final summaryText = jsonData['choices'][0]['text'];

        // Show the summary in a dialog
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('The News Summary'),
              contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              content: SingleChildScrollView(
                child: Text(summaryText),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        if (kDebugMode) {
          print('API Request Failed with Status Code: ${response.statusCode}');
          print('Response Body: ${response.body}');
        }
        throw Exception('Failed to summarize article');
      }
    } catch (error) {
      if (kDebugMode) {
        print('API Request Error: $error');
      }
    } finally {
      setState(() {
        isSummarizing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article['title'] ?? 'No title available'),
        backgroundColor: const Color(0xFF00C6AD),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(article['urlToImage'] ?? ''),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                article['title'] ?? 'No title available',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                article['description'] ?? 'No description available',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ExpandText(
                text: article['content'] ?? 'No content available',
                style: const TextStyle(fontSize: 16),
                isExpanded: isSummarizing,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isSummarizing
                    ? null
                    : () {
                        summarizeArticle(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C6AD),
                ),
                child: isSummarizing
                    ? const CircularProgressIndicator()
                    : const Text('Summarize Article'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpandText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool isExpanded;

  const ExpandText({
    Key? key,
    required this.text,
    required this.style,
    required this.isExpanded,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ExpandTextState createState() => _ExpandTextState();
}

class _ExpandTextState extends State<ExpandText> {
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.text,
          style: widget.style,
          maxLines: isExpanded ? null : 5, // Display all lines when expanded
          overflow: TextOverflow.ellipsis,
        ),
        if (!isExpanded)
          TextButton(
            onPressed: () {
              setState(() {
                isExpanded = true;
              });
            },
            child: const Text('Read more'),
          ),
      ],
    );
  }
}
