import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Scanner;
import behaviorism.utils.*;

public class Parser
{

  public static List<Poem> poems = new ArrayList<Poem>();
  public static List<Stanza> stanzas = new ArrayList<Stanza>();
  public static List<Line> lines = new ArrayList<Line>();
  public static Map<String, Word> words = new HashMap<String, Word>();
  public static List<Word> rankedWords = new ArrayList<Word>();

  public static void printCollocation(String wordStr)
  {
    Word word = words.get(wordStr);

    if (word == null)
    {
      System.err.println("this word doesn't exist!");
      return;
    }

    word.printCollocations();
    word.printCollocationsRank();
  }

  public static List<PoetryChain> connectWords(int minDepth, int maxDepth, int numChains)
  {
    List<PoetryChain> chains = new ArrayList<PoetryChain>();
    Word r1 = Utils.randomElement(words.values());
    Word r2 = Utils.randomElement(words.values());

    for (int i = 0; i < numChains; i++)
    {
      PoetryChain chain = connectWords(r1.word, r2.word, minDepth, maxDepth);

      if (chain != null)
      {
        chains.add(chain);
      }

      r1 = r2;
      r2 = Utils.randomElement(words.values());
    }

    return chains;
  }

  public static PoetryChain connectWords(String startStr, String endStr, int minDepth, int maxDepth)
  {
    // System.out.println("in connectWords... " + startStr + "-->" + endStr);
    Word start = words.get(startStr);
    Word end = words.get(endStr);

    if (start == null || end == null)
    {
      System.err.println("you have chosen a word that does not exist in this corpus!");
      return null;
    }

    //System.out.println("souce= " + source.word + "("+source.total+")-->" + target.word + "("+target.total+")");

    for (int i = 0; i < 10; i++)
    {
      Word source;
      Word target;
      boolean needToReverse;

      if (i % 2 == 0)
      //if (end.total > start.total)
      {
        source = end;
        target = start;
        needToReverse = false;
      }
      else
      {
        source = start;
        target = end;
        needToReverse = true;
      }
      List<Line> path = new ArrayList<Line>();
      List<Word> connectors = new ArrayList<Word>();

      boolean found = searchFor(0, Utils.randomInt(minDepth, maxDepth), source, target, path, connectors,
        new ArrayList<Word>(), new ArrayList<Line>());

      //System.out.println("#path = " + path.size());
      //System.out.println("#connectors = " + connectors.size());
      if (needToReverse == true)
      {
        Collections.reverse(path);
        Collections.reverse(connectors);
      }

      if (found == true)
      {
        // System.out.println("\n...it took " + i + "times");
        return new PoetryChain(path, connectors);
        //break;
      }
    }
    return null;
  }

  public static boolean searchFor(int depth, int maxDepth, Word start, Word target,
    List<Line> path, List<Word> connectors, List<Word> alreadySeenWords, List<Line> alreadySeenLines)
  {
    //System.out.println("in searchFor, starting with <" + start.word + "> and looking for <" + target.word + ">" );
    if (depth > maxDepth)
    {
      //System.out.println("depth too great! returning...");
      return false;
    }

    List<Line> tempSeenLines = new ArrayList<Line>();

    //System.out.println("start.lines size = " + start.lines.size());
    Collections.shuffle(start.lines);
    //sortLinesByRank(start.lines, -1);


    for (Line line : start.lines)
    {
      if (alreadySeenLines.contains(line))
      {
        //System.out.println("already seen this line!");
        continue;
      }

      if (line.words.contains(target))
      {
        if (depth != maxDepth - 1)
        {
          continue;
        }
        //System.out.println("found target!");
        path.add(line);
        return true;
      }

      alreadySeenLines.add(line);
      tempSeenLines.add(line);

      List<Word> shuffledWords = new ArrayList<Word>(line.words);
      sortWordsByRank(shuffledWords, -1);

      List<Word> tempSeenWords = new ArrayList<Word>();

      for (Word word : shuffledWords)
      {
        if (alreadySeenWords.contains(word))
        {
          //System.out.println("already seen this word!");
          continue;
        }
        alreadySeenWords.add(word);
        tempSeenWords.add(word);

        if (word.equals(start))
        {
          continue;
        }
        boolean found = searchFor(depth + 1, maxDepth, word, target, path, connectors,
          alreadySeenWords, alreadySeenLines);

        if (found == true)
        {
          path.add(line);
          connectors.add(word);
          return true;
        }
      }

      //alreadySeenWords.removeAll(tempSeenWords);
    }


    //alreadySeenLines.removeAll(tempSeenLines);
    return false;
  }

  public static void printPoems()
  {
    for (Poem poem : poems)
    {
      poem.printPoem();
    }
  }

  public static void printWordRank(int top, int bot)
  {
    for (Word word : rankedWords)
    {
      if (word.rank >= top && word.rank <= bot)
      {
        System.out.println("<" + word.word + "> rank: " + word.rank + " total: " + word.total);
      }
    }
  }

  public static void printLineRank(int top, int bot)
  {
    for (Line line : lines)
    {
      if (line.rank >= top && line.rank <= bot)
      {
        System.out.println("<" + line.text + "> rank: " + line.rank + " total: " + line.total);
      }
    }
  }

  public static void rankLines()
  {
    //ranks the lines that have the most total number of connections
    for (Line line : lines)
    {
      int numConnections = 0;
      for (Word word : line.words)
      {
        numConnections += word.total;
      }

      line.total = numConnections;
    }

    sortLinesByRank(lines, 1);

    int rank = 1;
    for (Line line : lines)
    {
      line.rank = rank++;
    }
  }

  public static void sortLinesByRank(List<Line> lines, final int dir)
  {
    Collections.sort(lines, new Comparator<Line>()
    {

      public int compare(Line a, Line b)
      {
        int int1 = (a).total;
        int int2 = (b).total;

        return (int2 - int1) * dir;
      }
    });
  }

  public static void sortWordsByRank(List<Word> words, final int dir)
  {
    Collections.sort(words, new Comparator<Word>()
    {

      public int compare(Word a, Word b)
      {
        int int1 = (a).total;
        int int2 = (b).total;

        return (int2 - int1) * dir;
      }
    });
  }

  public static void rankWords()
  {
    //System.out.println("words size = " + words.size());
    rankedWords = new ArrayList<Word>(words.values());

    //System.out.println("rankedWords size = " + rankedWords.size());
    sortWordsByRank(rankedWords, 1);

    int rank = 1;
    for (Word word : rankedWords)
    {
      word.rank = rank++;
    }
  }

  public static void loadInPoems(File file, int max)
  {
    Poem currentPoem = null;
    Stanza currentStanza = null;
    Line currentLine = null;
    boolean newStanza = true;
    int stanzaNum = 1;

    int idx = 1;
    try
    {
      BufferedReader in = new BufferedReader(new FileReader(file));
      String str;
      while ((str = in.readLine()) != null)
      {
        int poemNumber = -1;
        try
        {
          poemNumber = Integer.parseInt(str);
        }
        catch (NumberFormatException nfe)
        {
        }

        if (poemNumber > 0)
        {
          currentPoem = new Poem("" + poemNumber);
          poems.add(currentPoem);
          continue;
        }
        if (str.length() < 1)
        {
          newStanza = true;
          continue;
        }

        if (newStanza == true)
        {
          stanzaNum++;
          currentStanza = new Stanza(stanzaNum, currentPoem);
          stanzas.add(currentStanza);

          newStanza = false;
          currentPoem.addStanza(currentStanza);
        }

        currentLine = new Line(idx, str, currentStanza, currentPoem);
        lines.add(currentLine);
        currentStanza.addLine(currentLine);

        parseLineIntoWords(currentLine, currentStanza, currentPoem);

        if (++idx > max)
        {
          break;
        }
      }
      in.close();
    }
    catch (IOException e)
    {
      System.err.println("error in loadInPoems!");
      e.printStackTrace();
    }

    //okay now we are going to rank all of the collocations for each word
    rankCollocations(words.values());
  }

  public static void parseLineIntoWords(Line line, Stanza stanza, Poem poem)
  {
    Scanner wordScanner;

    Word currentWord = null;

    List<Word> collocations = new ArrayList<Word>();

    //System.err.println("scanning " + line);
    wordScanner = new Scanner(line.text);
    while (wordScanner.hasNext())
    {

	    //MAKE LOWER CASE
      String wordStr = wordScanner.next().toLowerCase().trim();

      //KEEP ORIGINAL CASE
      //String wordStr = wordScanner.next().trim();


      if (!wordStr.equals("--"))
      {
	      //REMOVE PUNCTUATION
        wordStr = wordStr.replaceAll("\\p{Punct}+", "");
      }
      currentWord = words.get(wordStr);

      if (currentWord == null)
      {
        currentWord = new Word(wordStr);
        words.put(wordStr, currentWord);
      }

      collocations.add(currentWord);

      currentWord.total++;

      line.addWord(currentWord);
      currentWord.addLine(line);
      currentWord.addStanza(stanza);
      currentWord.addPoem(poem);
    }


    for (Word word : collocations)
    {
      collocateWords(word, collocations);
    }
  }

  public static void rankCollocations(Collection<Word> words)
  {
    for (Word word : words)
    {
      for (Map.Entry<Word, Integer> entry : word.collocations.entrySet())
      {
        word.collocationsRank.put(entry.getValue(), entry.getKey());
      }
    }
  }

  public static void collocateWords(Word word, List<Word> collocations)
  {
    boolean addSelfAsCollocate = false;

    for (Word collocate : collocations)
    {
      if (word == collocate && addSelfAsCollocate == false)
      {
        //don't add myself unless i really appear more than once in line.
        addSelfAsCollocate = true;
        continue;
      }

      Integer numTimesCollocated = word.collocations.get(collocate);

      if (numTimesCollocated == null)
      {
        word.collocations.put(collocate, new Integer(1));
      }

      else
      {
        word.collocations.put(collocate, new Integer(numTimesCollocated + 1));
      }
    }
  }
}
