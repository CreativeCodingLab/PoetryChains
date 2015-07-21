import behaviorism.utils.Utils;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;

public class CollocationNet
{

	public int MAX_COLLOCATES = 10;

	public CollocationNet() {
	}

	public void filterShortWords(List<Word> cos) {
		for (int i = cos.size() - 1; i >= 0; i--) {
			Word w = cos.get(i);
			if (w.word.length() < 3 || w.collocationsRank.size() <= 1) {
				cos.remove(w);
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


	public List<Word> getCollocations(Word word)
	{

		//word.printCollocationsRank();

		Set<Word> collocationSet = word.collocations.keySet();

		//System.out.println("here...\n");
		//System.out.println(collocationSet);


		//List<Word> collocations =
		//  Utils.randomElements(collocationSet, Math.min(MAX_COLLOCATES, collocationSet.size() - 1), 0, 5000); 
		List<Word> collocations =
			randomElements(collocationSet, Math.min(MAX_COLLOCATES, collocationSet.size() - 1));

		//System.out.println("MAX_COLLOCATES = " + MAX_COLLOCATES + ", collocationSet.size() - 1 = " + (collocationSet.size() - 1) + ", and size = " + collocations.size());
		filterShortWords(collocations);


		/*
		   System.err.println("YES PARENT");
		   System.err.println("does the parent's collocations contain the parent " + centerGeom.word + "?");
		   if (collocations.contains(centerGeom.connectedNode.word))
		   {
		   System.err.println("YES");
		   collocations.remove(centerGeom.connectedNode.word);
		   }
		   else
		   {
		   System.err.println("NOPE");
		   collocations = collocations.subList(0, collocations.size());
		   }

		 */

		return collocations;
	}

}
