
module org.golo.lookahead;

public class Lookahead(T) {
	
	public this(T[] array, T sentinel = T.init) {
		this.array = array;
		this.sentinel = sentinel;
	}
	
	public void consume(size_t howmuch=1) {
		size_t i = 0;
		while (array.length && howmuch--) {
			array = array [1 .. $];
		}
	}
	
	public T get(size_t howmuch=1) {
		if (howmuch < array.length) {
			return array[howmuch];
		} else {
			return sentinel;
		}
	}
	
	private T[] array;
	private T sentinel;
}
