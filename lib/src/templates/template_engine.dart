class TemplateEngine {
  static String render(String template, Map<String, String> variables) {
    String result = template;
    variables.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });
    return result;
  }

  static String renderFromFile(
    String templateContent,
    Map<String, String> variables,
  ) {
    return render(templateContent, variables);
  }
}
