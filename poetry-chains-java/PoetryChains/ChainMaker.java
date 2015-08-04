import behaviorism.utils.Utils;
import java.awt.Point;
import java.awt.event.KeyEvent;
import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

public class ChainMaker {

  static boolean OUTPUT_JSON = true;

  public Word lastSelected = null;

  public static void main(String[] args) {

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

    //System.err.println("TOTAL NUMBER WORDS = " + Parser.rankedWords.size());

    //A
    if (args.length == 0) {
      makeChains(null);
    } else {
      System.err.println("Seeding PoetryChain:Chain with " + args[0]);
      Word sw = Parser.words.get(args[0]);

      if (sw != null) {
        makeChains(sw);
      } else {
        makeChains(null);
      }
    }


  }

  private static void makeChains(Word startWord)
  {
    List<PoetryChain> chains;
    if (startWord == null) {
      chains = Parser.connectWords(5, 10, 2);
    } else {
      chains = Parser.connectWords(startWord, 5, 10, 2);
    }
    if (OUTPUT_JSON) {

      System.out.print("[\n");

      //OUTPUT JSON
      for (int i = 0; i < chains.size(); i++) {
        PoetryChain chain = chains.get(i);
        chain.printChainJSON();
        if (i < chains.size() - 1) {
          System.out.print(",\n");
        }
      }

      System.out.print("]\n");
      System.out.print("\n");

    } else {

      //OUTPUT POEM
      for (PoetryChain chain : chains) {
        chain.printChain();
        System.out.print("\n\n");
      }
    }

  }


  /*

     [
     {
     "word": "unremembered",
     "colocations": [
     {"val": "stars", "amt":4},
     {"val": "stars", "amt":4},
     {"val": "stars", "amt":4},
     {"val": "stars", "amt":4}
     ]
     },
     {
     "word": "unremembered",
     "colocations": [
     {"val": "stars", "amt":4},
     {"val": "stars", "amt":4},
     {"val": "stars", "amt":4},
     {"val": "stars", "amt":4}
     ]
     }
     ]





*/



}
