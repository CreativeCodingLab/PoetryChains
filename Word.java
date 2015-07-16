
import com.google.common.collect.Multimap;
import com.google.common.collect.TreeMultimap;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

public class Word implements Comparable<Word>
{
  public String word;
  public int rank;
  int total;
  public List<Line> lines = new ArrayList<Line>();
  List<Stanza> stanzas = new ArrayList<Stanza>();
  List<Poem> poems = new ArrayList<Poem>();

  Map<Word, Integer> collocations = new TreeMap<Word, Integer>();

  Multimap<Integer, Word> collocationsRank; // = HashMultimap.create();


  public Word(String word)
  {
    this.word = word;
    this.total = 0;
    collocationsRank = TreeMultimap.create();
  }

  public void printWord()
  {
    System.out.print(word + " ");
  }

  public void addLine(Line line)
  {
    lines.add(line);
  }
  public void addStanza(Stanza stanza)
  {
    stanzas.add(stanza);
  }
  public void addPoem(Poem poem)
  {
    poems.add(poem);
  }

  public void printCollocations()
  {
    System.out.println("The word " + word + " is collocated with " + collocations.size() + " distinct words.");

    for (Map.Entry<Word, Integer> entry : collocations.entrySet())
    {
      System.err.println("<" + entry.getKey().word + "> (" + entry.getValue() + ")");
    }
  }

  public void printCollocationsRank()
  {
    System.out.println("The word " + word + " is collocated with " + collocations.size() + " distinct words.");

    //System.out.println(collocationsRank);

    List<Map.Entry<Integer, Collection<Word>>> set = new ArrayList<Map.Entry<Integer, Collection<Word>>>(collocationsRank.asMap().entrySet());

    Collections.reverse(set);

    for (Map.Entry<Integer, Collection<Word>> entry : set )
    {
      System.out.println(entry.getKey() + " entries:");
      for (Word w : entry.getValue())
      {
        System.out.println(w);
      }
      System.out.println("");
    }
  }

  public int compareTo(Word obj)
  {
    return word.compareTo(obj.word);
  }

  @Override
  public String toString()
  {
    return word;
  }


}
