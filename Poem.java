import java.util.ArrayList;
import java.util.List;

public class Poem 
{
  String title;
  List<Stanza> stanzas = new ArrayList<Stanza>();

  public Poem(String title)
  {
    this.title = title;
  }

  public void addStanza(Stanza stanza)
  {
    stanzas.add(stanza);
  }

  public void printPoem()
  {
    System.out.println(this.title);
    for (Stanza stanza : stanzas)
    {
      stanza.printStanza();
      System.out.println("");
    }
  }
}
