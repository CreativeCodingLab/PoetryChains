
import java.awt.Point;
import java.awt.event.KeyEvent;
import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

public class ChainMaker {

  public enum MODE
  {
    DISPERSION,
    AMBIENT,
    NET
  }

  public Word lastSelected = null;

  public static void main(String[] args)
  {
  
	 int NUM_LINES = 20000;


	  //1. LOAD STUFF IN AND DO INITIAL ANALYSIS
    Parser.loadInPoems(new File("EmilyDickinsonPoems.txt"), NUM_LINES);
    Parser.rankWords();
    Parser.rankLines();

    //Parser.printPoems();
    Parser.printWordRank(1, 10);
    //Parser.printLineRank(3900, 5000);

    PoetryChain pc = Parser.connectWords("wilderness", "society", 18, 20);
    pc.printChain();
//Parser.printPoems();

    //Parser.printCollocation("my");

    System.err.println("TOTAL NUMBER WORDS = " + Parser.rankedWords.size());

    //A
           // makeChains();
    

    //or, B
   // Word word = Utils.randomElement(Parser.rankedWords, 0, 200);
     
//makeNets(word, false); //add this datastruct back in
 
  }


  private void makeChains()
  {
    List<PoetryChain> chains = Parser.connectWords(5, 9, 50);
    for (PoetryChain chain : chains)
    {
      chain.printChain();
      System.out.println("\n\n");

    }
  }

}
