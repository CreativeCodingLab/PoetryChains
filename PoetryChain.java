import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

public class PoetryChain
{

  List<Line> lines;
  List<Word> words; //words that connect the lines

  public PoetryChain(List<Line> lines, List<Word> words)
  {
    this.lines = lines;
    this.words = words;
  }

  public void printChain()
  {
    for (int i = 0; i < lines.size(); i++)
    {
      lines.get(i).printLine();
      if (i < lines.size() - 1)
      {
        System.out.println("<" + words.get(i).word + ">");
      }
    }
  }

}
