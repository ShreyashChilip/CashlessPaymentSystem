import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const String apiKey = '';
  final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

  Future<String?> analyzeTransactions({
    required List<Map<String, dynamic>> transactions,
    required String analysisType,
    required String studentName,
  }) async {
    try {
      String prompt = '';
      
      switch (analysisType) {
        case 'spending_summary':
          prompt = '''
          Analyze the following transaction history for student $studentName and provide a clear summary of their spending habits:
          - Focus on patterns in food choices (healthy vs junk)
          - Identify peak spending times
          - Calculate average daily/weekly spending
          - Highlight any concerning patterns
          Format the response in clear sections with bullet points where appropriate.
          Transaction data: $transactions
          ''';
          break;
          
        case 'improvement_suggestions':
          prompt = '''
          Based on the following transaction history for student $studentName, suggest specific improvements:
          - Recommend better food choices if needed
          - Suggest budget management tips
          - Provide actionable steps for better spending habits
          - Include positive reinforcement for good choices
          Format the suggestions in a constructive and encouraging way.
          Transaction data: $transactions
          ''';
          break;
          
        case 'health_analysis':
          prompt = '''
          Analyze the health implications of $studentName's food choices based on their transaction history:
          - Calculate the ratio of healthy vs unhealthy food choices
          - Identify nutritional concerns
          - Suggest balanced meal options
          - Highlight positive choices made
          Present the analysis in a parent-friendly format.
          Transaction data: $transactions
          ''';
          break;
      }

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text;
    } catch (e) {
      print('AI Analysis Error: $e');
      return 'Failed to analyze transactions. Please try again later.';
    }
  }
}