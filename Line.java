
import java.util.ArrayList;
import java.util.List;

public class Line 
{
  public int lineNumber;
  String text;
  Stanza stanza;
  Poem poem;
  List<Word> words = new ArrayList<Word>();
  int total; //= total connections
  int rank; // higher rank = more connections

  public Line(int lineNumber, String text, Stanza stanza, Poem poem)
  {
    this.lineNumber = lineNumber;
    this.text = text;
    this.stanza = stanza;
    this.poem = poem;
  }

  public void addWord(Word word)
  {
    words.add(word);
  }

  public void printLine()
  {
    for (Word word : words)
    {
      word.printWord();
    }
    System.out.print("");
  }

}
