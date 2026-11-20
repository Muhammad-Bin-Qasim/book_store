import '../models/book.dart';

/// Fictional and public-domain sample records for the admin-only seed action.
final List<Book> sampleBooks = _buildSampleBooks();

List<Book> _buildSampleBooks() {
  final now = DateTime.now();
  return <Book>[
    _book('pride-and-prejudice', 'Pride and Prejudice', 'Jane Austen', 'Romance',
        'Elizabeth Bennet navigates family expectations, first impressions, and the surprising path to love in Jane Austen’s beloved classic.', 12.50, true, 240, 4.8, 1280, now.subtract(const Duration(days: 5400)), 'prideprejudice'),
    _book('frankenstein', 'Frankenstein', 'Mary Shelley', 'Gothic Fiction',
        'A brilliant experiment gives life to a lonely creature, setting creator and creation on a haunting journey through ambition and responsibility.', 10.00, true, 210, 4.5, 860, now.subtract(const Duration(days: 7200)), 'frankenstein'),
    _book('the-midnight-library', 'The Midnight Library', 'Mara Ellison', 'Fantasy',
        'Between one life and the next, a mapmaker discovers a library of possible futures and the courage to choose an imperfect present.', 18.75, true, 195, 4.7, 640, now.subtract(const Duration(days: 35)), 'midnightlibrary'),
    _book('the-glass-orchard', 'The Glass Orchard', 'Nadia Vale', 'Mystery',
        'A locked greenhouse, a vanished botanist, and a village full of secrets draw investigator Lena Ward into a beautiful, intricate puzzle.', 16.25, false, 170, 4.3, 312, now.subtract(const Duration(days: 18)), 'glassorchard'),
    _book('dracula', 'Dracula', 'Bram Stoker', 'Gothic Fiction',
        'A solicitor’s journal, a storm-lashed coast, and a count with a dreadful secret shape this landmark tale of suspense.', 11.50, true, 225, 4.6, 940, now.subtract(const Duration(days: 6000)), 'dracula'),
    _book('small-hours', 'The Small Hours', 'Leah Winters', 'Contemporary Fiction',
        'Three siblings return to their seaside hometown and uncover the quiet promises that have held their family together.', 19.00, false, 158, 4.2, 204, now.subtract(const Duration(days: 52)), 'smallhours'),
    _book('atlas-of-embers', 'Atlas of Embers', 'Theo Mercer', 'Fantasy',
        'An apprentice cartographer maps a kingdom that changes overnight and discovers that every border is hiding an old bargain.', 22.00, true, 188, 4.8, 530, now.subtract(const Duration(days: 12)), 'atlasembers'),
    _book('the-blue-hour', 'The Blue Hour Case', 'Ari Patel', 'Mystery',
        'When a clockmaker disappears at dusk, a curious archivist follows a trail of coded receipts through the city’s oldest quarter.', 17.50, false, 145, 4.1, 178, now.subtract(const Duration(days: 120)), 'bluehourcase'),
    _book('journey-to-center', 'Journey to the Center of the Earth', 'Jules Verne', 'Adventure',
        'A professor and his companions descend through a volcanic passage into a lost world in this spirited adventure classic.', 13.75, true, 202, 4.4, 720, now.subtract(const Duration(days: 6800)), 'journeycenter'),
    _book('orbit-of-home', 'Orbit of Home', 'Samira Chen', 'Science Fiction',
        'A repair pilot receives an impossible signal from a derelict station and must decide what home means beyond the edge of known space.', 20.50, false, 162, 4.6, 286, now.subtract(const Duration(days: 44)), 'orbitofhome'),
    _book('letters-from-linden', 'Letters from Linden Street', 'Oliver Finch', 'Romance',
        'A misplaced bundle of letters brings a neighborhood baker and a meticulous conservator together one handwritten page at a time.', 15.00, false, 136, 4.0, 152, now.subtract(const Duration(days: 260)), 'lindenletters'),
    _book('the-last-lighthouse', 'The Last Lighthouse', 'Elena Brooks', 'Adventure',
        'A storm keeper and a young navigator race to restore a remote beacon before winter closes the sea road.', 18.00, true, 176, 4.5, 401, now.subtract(const Duration(days: 28)), 'lastlighthouse'),
    _book('little-women', 'Little Women', 'Louisa May Alcott', 'Classics',
        'The four March sisters grow through hardship, ambition, and affection in a warm, enduring portrait of family life.', 12.00, true, 218, 4.7, 1020, now.subtract(const Duration(days: 6400)), 'littlewomen'),
    _book('a-river-of-stars', 'A River of Stars', 'Imani Reed', 'Science Fiction',
        'On a generation ship bound for a distant world, a young botanist finds a clue that could change the crew’s destination.', 21.25, false, 149, 4.4, 219, now.subtract(const Duration(days: 8)), 'riverofstars'),
    _book('the-mapmakers-secret', 'The Mapmaker’s Secret', 'Rafael Costa', 'Historical Fiction',
        'In a port city at the dawn of a new age, a mapmaker’s apprentice discovers that one missing island was erased on purpose.', 19.50, false, 131, 4.2, 166, now.subtract(const Duration(days: 190)), 'mapmakerssecret'),
    _book('the-wildwood-key', 'The Wildwood Key', 'Mara Ellison', 'Fantasy',
        'A found key opens a hidden woodland where forgotten stories still have the power to alter the living world.', 17.95, false, 155, 4.6, 247, now.subtract(const Duration(days: 56)), 'wildwoodkey'),
    _book('the-moonstone', 'The Moonstone', 'Wilkie Collins', 'Mystery',
        'A priceless diamond disappears from an English country house, and a series of narrators reveal the mystery piece by piece.', 14.25, true, 181, 4.3, 398, now.subtract(const Duration(days: 5800)), 'moonstone'),
    _book('garden-of-small-things', 'The Garden of Small Things', 'Nadia Vale', 'Contemporary Fiction',
        'A retired teacher and her new neighbor restore an overgrown garden and find that second chances can take root anywhere.', 16.75, false, 124, 4.1, 143, now.subtract(const Duration(days: 3)), 'gardenofsmallthings'),
  ];
}

Book _book(
  String id,
  String title,
  String author,
  String genre,
  String description,
  double price,
  bool bestseller,
  int popularity,
  double rating,
  int ratingCount,
  DateTime releaseDate,
  String imageSeed,
) =>
    Book(
      id: id,
      title: title,
      author: author,
      genre: genre,
      description: description,
      coverUrl: 'https://picsum.photos/seed/$imageSeed/300/450',
      price: price,
      isBestseller: bestseller,
      releaseDate: releaseDate,
      popularity: popularity,
      avgRating: rating,
      ratingCount: ratingCount,
    );
