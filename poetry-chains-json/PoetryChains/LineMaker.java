import behaviorism.utils.Utils;
import java.awt.Point;
import java.awt.event.KeyEvent;
import java.io.File;
import java.util.*;


public class LineMaker {

  static boolean OUTPUT_JSON = true;
  static int MAX_LINES = 10; //max collocated lines per iteration
  static int NUM_LINES = 5; //num iterations

  public Word lastSelected = null;

  public static void main(String[] args)
  {

    int NUM_LINES = 2000000;

    //1. LOAD STUFF IN AND DO INITIAL ANALYSIS
    Parser.loadInPoems(new File("EmilyDickinsonPoems.txt"), NUM_LINES);
    Parser.rankWords();
    //Parser.rankLines();

    //Parser.printPoems();
    //Parser.printWordRank(1, 10);
    //Parser.printLineRank(3900, 5000);

    // PoetryChain pc = Parser.connectWords("eye", "eyes", 8,8);
    // pc.printChain();
    //Parser.printPoems();

    //Parser.printCollocation("my");

    System.err.println("TOTAL NUMBER WORDS = " + Parser.rankedWords.size());

    //A
    //makeChains();

    //or, B
    //Word word = Utils.randomElement(Parser.rankedWords, 10000, 18000); //get a low frequency word
    //makeNets(word, 10);

    makeLines();
  }




	public static <T> List<T> randomElements(Collection<T> collection, int howMany) {
		if (collection.size() < howMany) {
			System.err.println("ERROR : you are requesting too many elements from this list!");
			return null;
		}

		List<T> list = new ArrayList<T>(collection);

		Collections.shuffle(list);

		List<T> returnList = new ArrayList<T>();
		for (int i = 0; i < howMany; i++) {
			returnList.add(list.get(i));
		}
		return returnList;
	}



  public static String removePuncationAndCapitals(Line l) {
    
    String s = "";
    for (Word word : l.words)
    {
      s = s + word + " ";
    }

    s = s.replaceAll("\"", "\\\\\"");

    return s;
  }

  private static void makeLines() {
    Set<Line> uniquelist;
    List<Line> lines;
    Word word;
    Line line;

    lines = Parser.lines;



    if (OUTPUT_JSON) {
      System.out.print("[\n");
    }


    for (int i = 0; i < NUM_LINES; i++) {
      //1. grab a line at random
      line = LineMaker.randomElements(lines, 1).get(0);

      if (OUTPUT_JSON) {
        //System.out.print("\t{\n\t\t\"line\":\"" + line.text + "\",\n");
        System.out.print("\t{\n\t\t\"line\":\"" + removePuncationAndCapitals(line) + "\",\n");
      } else {
        //System.out.println("line = " + line.text);
        System.out.println("line = " + removePuncationAndCapitals(line));

      }


      for (;;) {

        //2. pick a word in that line at random
        word = LineMaker.randomElements(line.words, 1).get(0);

        //3. grab every other line that contains that word
        uniquelist = new HashSet<Line>(word.lines); //a word appear more than once in a line!

        if (uniquelist.size() > 1) { //make sure that this is not the only time the word appears in the entire corpus!

          if (OUTPUT_JSON) {
            System.out.print("\t\t\"word\":\"" + word + "\",\n");
          } else {
            System.out.println("word = " + word);
          }

          break;

        }
      }

      lines = new ArrayList<Line>(uniquelist);
      lines = lines.subList(0, Math.min(lines.size(), MAX_LINES - 1));

      if (OUTPUT_JSON) {
        System.out.print("\t\t\"lines\":[\n");
      }

      for (int j = 0; j < lines.size(); j++) {

        Line l = lines.get(j);

        if (OUTPUT_JSON) {
          //System.out.print("\t\t\t\"" + l.text + "\"");
          System.out.print("\t\t\t\"" + removePuncationAndCapitals(l) + "\"");
          
          if (j < lines.size() - 1) {
            System.out.print(",\n");
          } else {
            System.out.print("\n");
          }
        } else {
          System.out.println(l.stanza.stanzaNum + ":" + l.lineNumber + ": " + removePuncationAndCapitals(line));
        }
      }

      if (OUTPUT_JSON) {

        if (i < NUM_LINES - 1) {
          System.out.print("\t\t]\n\t},\n");
        } else {
          System.out.print("\t\t]\n\t}\n]\n");

        }
      }

    }


  }






}
