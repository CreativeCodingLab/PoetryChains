import behaviorism.utils.Utils;
import java.awt.Point;
import java.awt.event.KeyEvent;
import java.io.File;
import java.util.*;


public class LineMaker {

  static boolean OUTPUT_JSON = true;
  static int MAX_LINES = 20; //max collocated lines per iteration
  static int NUM_LINES = 5; //num iterations

  public Word lastSelected = null;

  public static void main(String[] args)
  {

    int NUM_LINES = 2000000;

    //1. LOAD STUFF IN AND DO INITIAL ANALYSIS
    Parser.loadInPoems(new File("EmilyDickinsonPoems.txt"), NUM_LINES);
    Parser.rankWords();

    if (args.length == 0) {
      makeLines(null);
    } else {
      System.err.println("Seeding PoetryChain:Lines with " + args[0]);
      Word sw = Parser.words.get(args[0]);

      if (sw != null) {
        Line seedLine = LineMaker.randomElements(sw.lines, 1).get(0);
        makeLines(seedLine);
      } else {
        makeLines(null);
      }
    }


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

private static void testMe() {

Word w = Parser.words.get("midnight\"");

System.out.println("w = " + w);


    List<Line> lines = w.lines;

   // Line line = lines.get(7);

    for (Line line : lines) {

     System.out.println(line.text);

     int sIdx = line.calcStartIndexOfWordInLine(w);
     int eIdx = line.calcEndIndexOfWordInLine(w);

     System.out.print("\t\t\"sIdx\":\"" + sIdx + "\",\n");
     System.out.print("\t\t\"eIdx\":\"" + eIdx + "\",\n");


   }


  System.exit(0);


}

  private static void makeLines(Line seedLine) {

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
      if (i == 0 && seedLine != null) {
        line = seedLine;
      } else {
        line = LineMaker.randomElements(lines, 1).get(0);
      }
      if (OUTPUT_JSON) {

        // System.out.print("\t{\n\t\t\"line\":\"" + line.text.replaceAll("\"", "\\\\\"") + "\",\n");
        //System.out.print("\t{\n\t\t\"line\":\"" + removePuncationAndCapitals(line) + "\",\n");

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

            int sIdx = line.calcStartIndexOfWordInLine(word);
            int eIdx = line.calcEndIndexOfWordInLine(word);

    System.out.print("\t\t\"sIdx\":\"" + sIdx + "\",\n");
    System.out.print("\t\t\"eIdx\":\"" + eIdx + "\",\n");



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

        int sIdx = l.calcStartIndexOfWordInLine(word);
        int eIdx = l.calcEndIndexOfWordInLine(word);

        if (OUTPUT_JSON) {

        //   System.out.print("\t\t\t{\"line\":\"" + l.text.replaceAll("\"", "\\\\\"") + "\",\"sIdx\":"+sIdx+",\"eIdx\":"+eIdx+"}");
          //System.out.print("\t\t\t\"" + removePuncationAndCapitals(l) + "\"");


          //System.out.print("\t\t\t{\"line\":\"" + l.text + "\",\"sIdx\":"+sIdx+",\"eIdx\":"+eIdx+"}");
          System.out.print("\t\t\t{\"line\":\"" + removePuncationAndCapitals(l) + "\",\"sIdx\":"+sIdx+",\"eIdx\":"+eIdx+"}");
          ///System.out.print("\t\t\t\"" + removePuncationAndCapitals(l) + "\"");

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
