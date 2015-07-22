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
    makeChains();

    //or, B
    //Word word = Utils.randomElement(Parser.rankedWords, 10000, 18000); //get a low frequency word
    //makeNets(word, 10); 
    
  }

  private static void makeChains()
  {
    List<PoetryChain> chains = Parser.connectWords(5, 10, 10);

    if (OUTPUT_JSON) {
  
      //OUTPUT JSON
      for (int i = 0; i < chains.size(); i++) {
        PoetryChain chain = chains.get(i);
        chain.printChainJSON();
        if (i < chains.size() - 1) {
          System.out.print(",\n");
        }
      }

      System.out.print("\n");
  
    } else {

      //OUTPUT POEM
      for (PoetryChain chain : chains) {
        chain.printChain();
        System.out.print("\n\n");
      }

    }


  }


  public static void makeNets(final Word word, int numberOfNets)
  {
    Word w = word;

    if (OUTPUT_JSON) {
      System.out.print("[\n");
    }

    for (int i = 0; i < numberOfNets; i++) {

      if (OUTPUT_JSON) {
        System.out.print("\t{\n\t\t\"word\":\"" + w + "\",\n\t\t\"colocations\": [\n");
      } else {
        System.out.print(w + "\n");
      }

      CollocationNet collocationNet = new CollocationNet();

      List<Word> colos = collocationNet.getCollocations(w);

      for (int j = 0; j < colos.size(); j++) {
        Word cw = colos.get(j);

        if (OUTPUT_JSON) {
          System.out.print("\t\t\t{\"val\":\""+cw.word+"\",\"amt\":"+ w.collocations.get(cw)+"}" );

          if (j < colos.size() - 1) {
            System.out.print(",\n");
          }
        } else {
          System.out.println("\t" + cw.word + " (" + w.collocations.get(cw) + ")");
        }
      }

      if (OUTPUT_JSON) {
        System.out.print("\n\t\t]\n\t}");

        if (i < numberOfNets - 1) {
          System.out.print(",\n");
        }
      } else {
          System.out.print("\n");
      }

      w = Utils.randomElement(colos);

    }

    if (OUTPUT_JSON) {
      System.out.print("\n]\n");
    } else {
      System.out.print("\n");
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
