import 'package:flutter/material.dart';

class BookListScreen extends StatefulWidget {
  final List<dynamic> books;
  final String title;

  const BookListScreen({
    super.key,
    required this.books,
    this.title = 'Books',
  });

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  bool isGrid = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                isGrid = !isGrid;
              });
            },
            child: Text(
              isGrid ? 'List View' : 'Grid View',
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: isGrid
            ? GridView.builder(
                itemCount: widget.books.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.65,
                ),
                itemBuilder: (context, index) {
                  final book = widget.books[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/book-details',
                        arguments: book,
                      );
                    },
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(10),
                            child: Image.network(
                              book['coverImageUrl'],
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book['title'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          book['author'],
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            : ListView.builder(
                itemCount: widget.books.length,
                itemBuilder: (context, index) {
                  final book = widget.books[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/book-details',
                        arguments: book,
                      );
                    },
                    child: Container(
                      margin:
                          const EdgeInsets.only(bottom: 15),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(10),
                            child: Image.network(
                              book['coverImageUrl'],
                              width: 100,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  book['author'],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
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
      ),
    );
  }
}