import behaviorism.utils.Utils;
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
		//    makeChains();


		//or, B
		Word word = Utils.randomElement(Parser.rankedWords, 10000, 18000); //get a low frequency word
		System.out.println("makeNets ... word = " + word + "\n\n");

		makeNets(word); //add this datastruct back in

	}


	private static void makeChains()
	{
		List<PoetryChain> chains = Parser.connectWords(5, 9, 50);
		for (PoetryChain chain : chains)
		{
			chain.printChain();
			System.out.println("\n\n");

		}
	}



	public static void makeNets(final Word word)
	{
		Word w = word;

		for (int i = 0; i < 100; i++) {

			CollocationNet collocationNet = new CollocationNet();

			System.err.println("\n\nSTARTING WORD = " + w);

			List<Word> colos = collocationNet.getCollocations(w);

			for (Word cw : colos) {
				System.out.println(cw.word + " : " + w.collocations.get(cw));
			}

			w = Utils.randomElement(colos);

		}
	}




}
