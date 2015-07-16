
import java.util.ArrayList;
import java.util.List;

public class Stanza 
{
  int stanzaNum;
  Poem poem;
  List<Line> lines = new ArrayList<Line>();

  public Stanza(int stanzaNum, Poem poem)
  {
    this.stanzaNum = stanzaNum;
    this.poem = poem;
  }

  public void addLine(Line line)
  {
    lines.add(line);
  }

  public void printStanza()
  {
   for (Line line : lines)
    {
      line.printLine();
    }
  }
}
