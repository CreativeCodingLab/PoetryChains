
import java.util.ArrayList;
import java.util.List;

public class Line 
{
  public int lineNumber;
  String text;
  Stanza stanza;
  Poem poem;
  public List<Word> words = new ArrayList<Word>();
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

  public int calcStartIndexOfWordInLine(Word w) {
    int idx = 0;
    for (Word word : words) {
      //word.printWord();

      if (word.equals(w)) {
        //System.out.println("\nfound " + w.word + ", startIdx = " + idx);
        return idx;
      }

      idx+=word.word.length();
      idx++; //handle the space
    }

    System.out.println("ERROR: never found the word: " + w.word);

    return -1;
  }

  public int calcEndIndexOfWordInLine(Word w) {
    int idx = 0;
    for (Word word : words) {
      //word.printWord();

      if (word.equals(w)) {
        //System.out.println("\nfound " + w.word + ", endIdx = " + (idx+word.word.length()));
        return idx+word.word.length();
      }

      idx+=word.word.length();
      idx++; //handle the space
    }

    System.out.println("ERROR: never found the word: " + w.word);

    return -1;
  }


  public void printLine()
  {
    for (Word word : words)
    {
      word.printWord();
    }
    System.out.print("");
  }

  public void printLineEscaped()
  {
    for (Word word : words)
    {
      word.printWordEscaped();
    }
    System.out.print("");
  }

}
