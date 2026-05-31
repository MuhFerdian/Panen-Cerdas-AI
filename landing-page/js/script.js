document.addEventListener('DOMContentLoaded', () => {
    // Initialize AOS Animation
    AOS.init({
        once: true,
        offset: 50,
        duration: 800,
        easing: 'ease-in-out'
    });

    // Navbar Scroll Effect
    const navbar = document.querySelector('.navbar');
    window.addEventListener('scroll', () => {
        if (window.scrollY > 50) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }
    });

    // Active Nav Link Detection
    const navLinks = document.querySelectorAll('.nav-links a');
    const sections = document.querySelectorAll('section[id]');

    window.addEventListener('scroll', () => {
        let currentSection = '';

        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.clientHeight;
            if (window.pageYOffset >= sectionTop - 200) {
                currentSection = section.getAttribute('id');
            }
        });

        navLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href') === `#${currentSection}`) {
                link.classList.add('active');
            }
        });
    });

    // Mobile Menu Toggle (Simple alert for demo)
    const mobileBtn = document.querySelector('.mobile-menu-btn');
    if (mobileBtn) {
        mobileBtn.addEventListener('click', () => {
            alert('Menu navigasi (Responsive Sidebar bisa ditambahkan di sini)');
        });
    }

    // Smooth Scrolling for Anchor Links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            const targetId = this.getAttribute('href');
            if (targetId === '#') return;
            
            const targetElement = document.querySelector(targetId);
            if (targetElement) {
                e.preventDefault();
                const headerOffset = 80;
                const elementPosition = targetElement.getBoundingClientRect().top;
                const offsetPosition = elementPosition + window.pageYOffset - headerOffset;
  
                window.scrollTo({
                    top: offsetPosition,
                    behavior: "smooth"
                });
            }
        });
    });

    // Showcase Gallery Carousel
    const wrapper = document.getElementById('galleryWrapper');
    const items = document.querySelectorAll('.gallery-item');
    const prevBtn = document.querySelector('.prev-btn');
    const nextBtn = document.querySelector('.next-btn');
    
    if (wrapper && items.length > 0) {
        let currentIndex = 1; // Start from middle (assuming 3 visible)
        
        function updateGallery() {
            // Remove active from all
            items.forEach(item => item.classList.remove('active'));
            
            // Add active to current
            if (items[currentIndex]) {
                items[currentIndex].classList.add('active');
            }
            
            // For mobile (1 item visible), just translate index * -100%
            // For desktop (3 items visible), center the active one
            if (window.innerWidth <= 768) {
                wrapper.style.transform = `translateX(-${currentIndex * 100}%)`;
            } else {
                // If index is 0, shift right, if max, shift left
                if (currentIndex === 0) {
                    wrapper.style.transform = `translateX(33.333%)`;
                } else if (currentIndex === items.length - 1) {
                    wrapper.style.transform = `translateX(-${(items.length - 3) * 33.333 + 33.333}%)`;
                } else {
                    wrapper.style.transform = `translateX(-${(currentIndex - 1) * 33.333}%)`;
                }
            }
        }
        
        // Initialize
        updateGallery();
        
        // Resize listener
        window.addEventListener('resize', updateGallery);
        
        prevBtn.addEventListener('click', () => {
            if (currentIndex > 0) {
                currentIndex--;
                updateGallery();
            }
        });
        
        nextBtn.addEventListener('click', () => {
            if (currentIndex < items.length - 1) {
                currentIndex++;
                updateGallery();
            }
        });
    }
});
