import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

public class PoetryChain
{

  List<Line> lines;
  List<Word> words; //words that connect the lines
  Word first;
  Word last;

  public PoetryChain(List<Line> lines, List<Word> words)
  {
    this.lines = lines;
    this.words = words;
  }

  public void printChain()
  {
    for (int i = 0; i < lines.size(); i++)
    {
      Line line = lines.get(i);
      System.out.print("<" + line.poem.title + ">:\t");
      lines.get(i).printLine();

      if (i < lines.size() - 1)
      {
        System.out.print("\t <" + words.get(i).word + ">");
      }
      System.out.println("");
    }
  }

  public void first(Word word) {
      first = word;
  }
  public Word first() {
      return first;
  }

  public void last(Word word) {
      last = word;
  }
  public Word last() {
      return last;
  }

  public void printChainJSON() {
    System.out.print("[\n");

    for (int i = 0; i < lines.size(); i++)
    {
      System.out.print("\t{\n");

      Line line = lines.get(i);
      System.out.print("\t\t\"title\":\"" + line.poem.title + "\",\n");
      //lines.get(i).printLine();

      System.out.print("\t\t\"line\":\"");

      String text = line.text;
      text = text.replaceAll("\"", "\\\\\"");
      System.out.print(text);

      /*
      for (int j = 0; j < line.words.size(); j++) {
        Word w = line.words.get(j);
        String theWord = w.word;

        theWord = theWord.replaceAll("\"", "\\\\\"");

        System.out.print(theWord);
        if (j < line.words.size() - 1) {
          System.out.print(" ");
        }
      }
      */
      System.out.print("\",\n");


      if (i < lines.size() - 1)
      {
        System.out.print("\t\t\"connector\":\"" + words.get(i).word + "\"\n");
        System.out.print("\t},\n");
      } else {
          if (last != null) System.out.print("\t\t\"connector\":\"" + last.word + "\"\n");
          else System.out.print("\t\t\"connector\":\"\"\n");
         System.out.print("\t}\n");
      }
    }
    System.out.print("]");

  }


  /* not using this one... */
  /*
  public void printChainJson()
  {
    System.out.println("[");
    for (int i = 0; i < lines.size(); i++)
    {
      if (i > 0) {
        System.out.println(",");
      }
      System.out.println("{");
      Line line = lines.get(i);

      System.out.println("\t\"poem\": \"" + line.poem.title + "\",");
      System.out.print("\t\"line\": \"");
      line.printLineEscaped();
      System.out.print("\"");

      if (i < lines.size() - 1) {
        System.out.println(",");
        System.out.println("\t\"word\": \"" + words.get(i).word.replaceAll("\"", "\\\\\"") + "\"");
      }

      System.out.print("}");
    }
    System.out.println("]");
  }
  */

}
