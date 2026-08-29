import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          TextField(decoration: InputDecoration(labelText: 'Search by location or crime type', prefixIcon: Icon(Icons.search))),
          SizedBox(height: 24),
          Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(spacing: 8, runSpacing: 8, children: ['Lagos Mainland', 'Armed Robbery', 'Ikeja', 'Theft', 'Victoria Island'].map((s) => Chip(label: Text(s))).toList()),
          SizedBox(height: 24),
          Text('Popular Searches', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(spacing: 8, runSpacing: 8, children: ['Crime near me', 'Safe routes', 'Police stations', 'Hospitals'].map((s) => Chip(label: Text(s))).toList()),
        ]),
      ),
    );
  }
}
